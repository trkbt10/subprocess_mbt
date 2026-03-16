# trkbt10/subprocess

Node.js `child_process`-like subprocess management for MoonBit.

Built on top of `moonbitlang/async/process`, providing a higher-level API for spawning and managing child processes with automatic zombie prevention and IPC.

## Features

- **`exec`** — Run a shell command (`/bin/sh -c`), collect stdout/stderr
- **`exec_file`** — Run an executable directly, collect stdout/stderr
- **`spawn`** / **`spawn_shell`** — Spawn a process with streaming stdin/stdout/stderr pipes
- **`managed/ProcessManager`** — Track all spawned processes, reap completed ones, graceful shutdown
- **`ipc/socket`** — IPC socket server/client (AF_UNIX) with length-prefixed message framing
- **`ipc/IpcChannel`** — Unified channel abstraction over sockets and pipes

## Quick Start

```mbt nocheck
// Shell command execution
let result = @subprocess.exec("ls -la")
println(result.stdout)

// Direct file execution
let result = @subprocess.exec_file("git", args=["status"])
println(result.stdout)

// Spawn with streaming I/O
@async.with_task_group(async fn(group) {
  let child = @subprocess.spawn(group, "cat", pipe_stdin=true, pipe_stdout=true)
  child.stdin.unwrap().write("hello")
  child.stdin.unwrap().close()
  let output = child.stdout.unwrap().read_all()
  println(output.text())
  let _ = child.wait()
  group.return_immediately(())
})

// Managed process pool (zombie prevention)
let pm = @managed.ProcessManager::new()
let r = pm.exec("echo hello")
pm.shutdown()  // cancels all, waits, no zombies

// IPC socket
let server = @socket.Server::new("/tmp/my_app.sock")
let client = @socket.Connection::connect("/tmp/my_app.sock")
let conn = server.accept()
client.send("hello")          // length-prefixed message
let msg = conn.recv()         // => Some("hello")
client.close()
conn.close()
server.close()
```

## API Reference

### `trkbt10/subprocess`

| Function | Description |
|----------|-------------|
| `exec(command, cwd?, env?, inherit_env?, check?)` | Run shell command, return `ExecResult` |
| `exec_file(file, args?, cwd?, env?, inherit_env?, check?)` | Run executable, return `ExecResult` |
| `spawn(group, command, args?, ..., pipe_stdin?, pipe_stdout?, pipe_stderr?)` | Spawn with streaming I/O |
| `spawn_shell(group, command, ..., pipe_stdin?, pipe_stdout?, pipe_stderr?)` | Spawn shell command with streaming I/O |

### `trkbt10/subprocess/managed`

| Function | Description |
|----------|-------------|
| `ProcessManager::new()` | Create empty manager |
| `pm.exec(...)` / `pm.exec_file(...)` | Execute through manager |
| `pm.spawn(...)` / `pm.spawn_shell(...)` | Spawn tracked process |
| `pm.reap()` | Clean up completed processes |
| `pm.active_count()` | Count running processes |
| `pm.cancel_all()` | Cancel all running processes |
| `pm.shutdown()` | Cancel + wait all (zombie-safe) |
| `pm.wait_all()` | Wait for all without cancelling |

### `trkbt10/subprocess/ipc/socket`

| Function | Description |
|----------|-------------|
| `Server::new(path)` | Create IPC socket server |
| `server.accept()` | Accept connection (blocking) |
| `server.poll_accept(timeout_ms?)` | Non-blocking accept with timeout |
| `server.set_nonblocking()` | Set server to non-blocking mode |
| `server.close()` | Close server and remove socket file |
| `Connection::connect(path)` | Connect to an IPC socket server |
| `conn.send(message)` | Send length-prefixed UTF-8 message |
| `conn.recv()` | Receive length-prefixed message (`None` on EOF) |
| `conn.write_bytes(data)` | Send raw bytes |
| `conn.read_bytes(max_len?)` | Read raw bytes |
| `conn.peer_pid()` | Get peer process PID (macOS/Linux) |
| `conn.poll(timeout_ms?)` | Check for data readiness |
| `conn.close()` | Close connection |

### `trkbt10/subprocess/ipc`

| Function | Description |
|----------|-------------|
| `IpcChannel::from_socket(conn)` | Channel over IPC socket |
| `IpcChannel::from_child(child)` | Channel over subprocess pipes |
| `channel.send(msg)` / `channel.recv()` | Unified messaging |

## Requirements

- Native target only (`--target native`)
- `subprocess` / `managed`: Unix/macOS (uses `/bin/sh`)
- `ipc/socket`: Unix/macOS/Windows 10 Build 17063+ (`AF_UNIX`)
  - `peer_pid()` は macOS (`LOCAL_PEERPID`) と Linux (`SO_PEERCRED`) のみ対応
