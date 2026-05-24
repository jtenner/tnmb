# jtenner/telnet

MoonBit library project for implementing the TELNET protocol.

## Status

Bootstrap complete. The generated MoonBit project is in place, and the protocol/design wiki lives in [`docs/wiki/`](docs/wiki/README.md).

## Development commands

```sh
moon fmt
moon info
moon test
moon run cmd/main
moon run --target js cmd/bench
moon run --target native cmd/bench
```

## Benchmarks

A runnable benchmark package lives in [`cmd/bench`](cmd/bench). It supports JavaScript timing via `performance.now()` and native timing via a small monotonic-clock C stub:

```sh
moon run --target js cmd/bench
moon run --target native cmd/bench
```

The runner reports elapsed milliseconds, operations/second, approximate MB/s for byte-oriented workloads, and a checksum for each benchmark.

## Documentation

Start with [`docs/wiki/README.md`](docs/wiki/README.md). The wiki tracks normative RFC/IANA sources, implementation phases, option support, testing strategy, and maintenance rules.
