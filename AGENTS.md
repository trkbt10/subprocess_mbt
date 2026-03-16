# trkbt10/subprocess — Agent Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

## Project Structure

```
subprocess/             # Root: exec, exec_file, spawn, spawn_shell
├── managed/            # ProcessManager (zombie prevention, graceful shutdown)
├── ipc/                # IpcChannel (unified socket + pipe abstraction)
│   └── socket/         # Server, Connection, IpcError, message framing
│       └── ffi/        # C FFI declarations + platform C files
└── cmd/main/           # Example program
```

- Native target only: `moon check --target native`, `moon test --target native`
- Dependencies: `moonbitlang/async` (process, io)

## Coding Convention

- MoonBit code is organized in block style, each block is separated by `///|`.
- FFI: `extern "C"` declarations in `ffi/` packages, platform-split C files (`unix.c`, `windows.c`).
- Use `#borrow(param)` on FFI functions that receive borrowed pointers.
- Error types: `suberror` with `Show` impl.

## Tooling

- `moon fmt` — format code
- `moon check --target native` — type-check
- `moon test --target native` — run tests
- `moon info --target native` — update `.mbti` interfaces
- `moon run --target native cmd/main` — run example
