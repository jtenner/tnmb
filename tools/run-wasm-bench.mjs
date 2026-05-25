#!/usr/bin/env node
// Host runner for cmd/bench WebAssembly builds.
//
// Usage:
//   moon build --target wasm cmd/bench
//   node tools/run-wasm-bench.mjs _build/wasm/debug/build/cmd/bench/bench.wasm
//   moon build --target wasm-gc cmd/bench
//   bun tools/run-wasm-bench.mjs _build/wasm-gc/debug/build/cmd/bench/bench.wasm

import { readFile } from "node:fs/promises";
import { performance } from "node:perf_hooks";
import { spawnSync } from "node:child_process";

const requiredWasmFlags = [
  "--experimental-wasm-gc",
  "--experimental-wasm-typed-funcref",
  "--experimental-wasm-stringref",
];

if (
  process.env.MOONBIT_TELNET_WASM_BENCH_FLAGS !== "1" &&
  requiredWasmFlags.some((flag) => !process.execArgv.includes(flag))
) {
  const result = spawnSync(
    process.execPath,
    [
      ...requiredWasmFlags,
      ...process.execArgv,
      new URL(import.meta.url).pathname,
      ...process.argv.slice(2),
    ],
    {
      stdio: "inherit",
      env: { ...process.env, MOONBIT_TELNET_WASM_BENCH_FLAGS: "1" },
    },
  );
  process.exit(result.status ?? 1);
}

const wasmPath = process.argv[2];

if (!wasmPath) {
  console.error(
    "usage: node tools/run-wasm-bench.mjs <path-to-cmd/bench/bench.wasm>",
  );
  process.exit(2);
}

function nowUs() {
  return BigInt(Math.round(performance.now() * 1000));
}

function printChar(ch) {
  process.stdout.write(String.fromCharCode(ch));
}

const imports = {
  "moonbit:bench": {
    now_us: nowUs,
  },
  spectest: {
    print_char: printChar,
  },
};

const bytes = await readFile(wasmPath);
const { instance } = await WebAssembly.instantiate(bytes, imports);
const start = instance.exports._start ?? instance.exports["_start"];

if (typeof start !== "function") {
  console.error("wasm module does not export _start");
  process.exit(1);
}

start();
