#!/usr/bin/env node
// Collect repeated cmd/bench runs, aggregate every benchmark row, and print a
// markdown report.
//
// Examples:
//   node tools/collect-benchmarks.mjs --runs 5
//   node tools/collect-benchmarks.mjs --runs 3 --targets js-node,js-bun,wasm-node,wasm-bun,wasm-gc-bun
//   node tools/collect-benchmarks.mjs --no-build --out _build/bench/results.json --markdown _build/bench/results.md

import { mkdir, writeFile } from "node:fs/promises";
import { dirname } from "node:path";
import { spawnSync } from "node:child_process";
import { performance } from "node:perf_hooks";

const jsArtifact = "_build/js/debug/build/cmd/bench/bench.js";
const nativeArtifact = "_build/native/debug/build/cmd/bench/bench.exe";
const wasmArtifact = "_build/wasm/debug/build/cmd/bench/bench.wasm";
const wasmGcArtifact = "_build/wasm-gc/debug/build/cmd/bench/bench.wasm";

const targetDefinitions = {
  "js-node": {
    label: "js / node",
    required: ["node", "moon"],
    build: [["moon", ["build", "--target", "js", "cmd/bench"]]],
    run: ["node", [jsArtifact]],
  },
  "js-bun": {
    label: "js / bun",
    required: ["bun", "moon"],
    build: [["moon", ["build", "--target", "js", "cmd/bench"]]],
    run: ["bun", [jsArtifact]],
  },
  native: {
    label: "native",
    required: ["moon"],
    build: [["moon", ["build", "--target", "native", "cmd/bench"]]],
    run: [nativeArtifact, []],
  },
  "wasm-node": {
    label: "wasm / node",
    required: ["node", "moon"],
    build: [["moon", ["build", "--target", "wasm", "cmd/bench"]]],
    run: ["node", ["tools/run-wasm-bench.mjs", wasmArtifact]],
  },
  "wasm-bun": {
    label: "wasm / bun",
    required: ["bun", "moon"],
    build: [["moon", ["build", "--target", "wasm", "cmd/bench"]]],
    run: ["bun", ["tools/run-wasm-bench.mjs", wasmArtifact]],
  },
  "wasm-gc-bun": {
    label: "wasm-gc / bun",
    required: ["bun", "moon"],
    build: [["moon", ["build", "--target", "wasm-gc", "cmd/bench"]]],
    run: ["bun", ["tools/run-wasm-bench.mjs", wasmGcArtifact]],
  },
};

const defaultTargets = Object.keys(targetDefinitions);

function parseArgs(argv) {
  const settings = {
    runs: 3,
    targets: defaultTargets,
    build: true,
    strict: false,
    out: "",
    markdown: "",
  };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === "--runs") {
      settings.runs = Math.max(1, Number.parseInt(argv[++i] ?? "", 10));
    } else if (arg.startsWith("--runs=")) {
      settings.runs = Math.max(1, Number.parseInt(arg.slice("--runs=".length), 10));
    } else if (arg === "--targets") {
      settings.targets = parseTargets(argv[++i] ?? "");
    } else if (arg.startsWith("--targets=")) {
      settings.targets = parseTargets(arg.slice("--targets=".length));
    } else if (arg === "--no-build") {
      settings.build = false;
    } else if (arg === "--strict") {
      settings.strict = true;
    } else if (arg === "--out") {
      settings.out = argv[++i] ?? "";
    } else if (arg.startsWith("--out=")) {
      settings.out = arg.slice("--out=".length);
    } else if (arg === "--markdown") {
      settings.markdown = argv[++i] ?? "";
    } else if (arg.startsWith("--markdown=")) {
      settings.markdown = arg.slice("--markdown=".length);
    } else if (arg === "--help" || arg === "-h") {
      printHelp();
      process.exit(0);
    } else {
      throw new Error(`unknown argument: ${arg}`);
    }
  }
  if (!Number.isFinite(settings.runs) || settings.runs < 1) {
    throw new Error("--runs must be a positive integer");
  }
  return settings;
}

function parseTargets(value) {
  const targets = value.split(",").map((x) => x.trim()).filter(Boolean);
  for (const target of targets) {
    if (!targetDefinitions[target]) {
      throw new Error(`unknown target '${target}'. Known targets: ${defaultTargets.join(", ")}`);
    }
  }
  return targets.length === 0 ? defaultTargets : targets;
}

function printHelp() {
  console.log(`Usage: node tools/collect-benchmarks.mjs [options]\n\nOptions:\n  --runs N             Number of runs per target (default: 3)\n  --targets A,B        Comma-separated target list. Known: ${defaultTargets.join(", ")}\n  --no-build           Reuse existing artifacts instead of building first\n  --strict             Fail if a requested runtime is unavailable\n  --out PATH           Write raw and aggregate JSON\n  --markdown PATH      Write markdown report\n  -h, --help           Show this help\n`);
}

function commandExists(command) {
  const result = spawnSync("sh", ["-c", `command -v ${quoteShell(command)} >/dev/null 2>&1`], {
    stdio: "ignore",
  });
  return result.status === 0;
}

function quoteShell(value) {
  return `'${value.replaceAll("'", "'\\''")}'`;
}

function runCommand(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: "utf8",
    maxBuffer: 1024 * 1024 * 128,
    ...options,
  });
  if (result.status !== 0) {
    const rendered = [command, ...args].join(" ");
    throw new Error(
      `command failed (${result.status}): ${rendered}\n${result.stdout ?? ""}${result.stderr ?? ""}`,
    );
  }
  return result.stdout ?? "";
}

function parseBenchOutput(output) {
  const rows = [];
  for (const line of output.split(/\r?\n/)) {
    if (!line.includes(" | iters=")) continue;
    const match = line.match(
      /^(.+?) \| iters=(-?\d+) \| ms=(-?\d+) \| ops\/s=(-?\d+) \| MB\/s=(-?\d+) \| checksum=(-?\d+)$/,
    );
    if (!match) {
      throw new Error(`could not parse benchmark row: ${line}`);
    }
    rows.push({
      name: match[1],
      iterations: Number.parseInt(match[2], 10),
      ms: Number.parseInt(match[3], 10),
      opsPerSecond: Number.parseInt(match[4], 10),
      mbPerSecond: Number.parseInt(match[5], 10),
      checksum: Number.parseInt(match[6], 10),
    });
  }
  if (rows.length === 0) {
    throw new Error("benchmark output did not contain any parseable rows");
  }
  return rows;
}

function summarize(values) {
  const count = values.length;
  const avg = values.reduce((a, b) => a + b, 0) / count;
  const min = Math.min(...values);
  const max = Math.max(...values);
  const variance = values.reduce((a, b) => a + (b - avg) * (b - avg), 0) / count;
  return { avg, min, max, stddev: Math.sqrt(variance) };
}

function aggregateTarget(target, runs) {
  const byName = new Map();
  for (const run of runs) {
    for (const row of run.rows) {
      if (!byName.has(row.name)) byName.set(row.name, []);
      byName.get(row.name).push(row);
    }
  }
  return [...byName.entries()].map(([name, rows]) => {
    const checksums = [...new Set(rows.map((row) => row.checksum))];
    return {
      target,
      benchmark: name,
      runs: rows.length,
      iterations: rows[0]?.iterations ?? 0,
      ms: summarize(rows.map((row) => row.ms)),
      opsPerSecond: summarize(rows.map((row) => row.opsPerSecond)),
      mbPerSecond: summarize(rows.map((row) => row.mbPerSecond)),
      checksums,
      checksumStable: checksums.length === 1,
    };
  });
}

function formatNumber(value, digits = 0) {
  return value.toLocaleString("en-US", {
    maximumFractionDigits: digits,
    minimumFractionDigits: digits,
  });
}

function markdownReport(report) {
  const lines = [];
  lines.push("# Benchmark report");
  lines.push("");
  lines.push(`Generated: ${report.generatedAt}`);
  lines.push(`Runs per target: ${report.runsRequested}`);
  lines.push("");
  if (report.skipped.length > 0) {
    lines.push("## Skipped targets");
    lines.push("");
    lines.push("| Target | Reason |");
    lines.push("|---|---|");
    for (const skipped of report.skipped) {
      lines.push(`| ${skipped.target} | ${skipped.reason} |`);
    }
    lines.push("");
  }
  lines.push("## Aggregate results");
  lines.push("");
  lines.push("| Target | Benchmark | Runs | Avg ms | Avg ops/s | Avg MB/s | Min/Max MB/s | Checksum |");
  lines.push("|---|---|---:|---:|---:|---:|---:|---|");
  for (const row of report.aggregates) {
    lines.push(
      `| ${row.target} | \`${row.benchmark}\` | ${row.runs} | ${formatNumber(row.ms.avg, 1)} | ${formatNumber(row.opsPerSecond.avg, 1)} | ${formatNumber(row.mbPerSecond.avg, 1)} | ${formatNumber(row.mbPerSecond.min, 0)} / ${formatNumber(row.mbPerSecond.max, 0)} | ${row.checksumStable ? row.checksums[0] : `unstable: ${row.checksums.join(",")}`} |`,
    );
  }
  lines.push("");
  return lines.join("\n");
}

async function writeText(path, text) {
  if (!path) return;
  await mkdir(dirname(path), { recursive: true });
  await writeFile(path, text);
}

async function main() {
  const settings = parseArgs(process.argv.slice(2));
  const report = {
    generatedAt: new Date().toISOString(),
    runsRequested: settings.runs,
    targetsRequested: settings.targets,
    skipped: [],
    rawRuns: [],
    aggregates: [],
  };

  for (const target of settings.targets) {
    const definition = targetDefinitions[target];
    const missing = definition.required.filter((command) => !commandExists(command));
    if (missing.length > 0) {
      const reason = `missing command(s): ${missing.join(", ")}`;
      if (settings.strict) throw new Error(`${target}: ${reason}`);
      report.skipped.push({ target, reason });
      continue;
    }

    if (settings.build) {
      for (const [command, args] of definition.build) {
        console.error(`[${target}] build: ${command} ${args.join(" ")}`);
        runCommand(command, args, { stdio: ["ignore", "inherit", "inherit"] });
      }
    }

    const runs = [];
    for (let runIndex = 1; runIndex <= settings.runs; runIndex += 1) {
      const [command, args] = definition.run;
      console.error(`[${target}] run ${runIndex}/${settings.runs}: ${command} ${args.join(" ")}`);
      const started = performance.now();
      const output = runCommand(command, args);
      const elapsedMs = performance.now() - started;
      runs.push({
        target,
        label: definition.label,
        runIndex,
        elapsedMs,
        rows: parseBenchOutput(output),
      });
    }
    report.rawRuns.push(...runs);
    report.aggregates.push(...aggregateTarget(definition.label, runs));
  }

  const markdown = markdownReport(report);
  await writeText(settings.markdown, markdown);
  await writeText(settings.out, JSON.stringify(report, null, 2) + "\n");
  process.stdout.write(markdown);
}

main().catch((error) => {
  console.error(error.stack ?? String(error));
  process.exit(1);
});
