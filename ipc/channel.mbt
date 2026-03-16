///|
/// A bidirectional IPC channel for exchanging messages.
///
/// Can be backed by either a Unix domain socket connection
/// or a subprocess pipe pair (stdin/stdout).
pub(all) enum IpcChannel {
  /// Channel backed by a Unix domain socket connection.
  /// Uses length-prefixed binary framing.
  Socket(@socket.Connection)
  /// Channel backed by a subprocess (write to stdin, read from stdout).
  /// Uses newline-delimited text framing.
  Pipe(@subprocess.ChildProcess)
}

///|
/// Create an IPC channel from a Unix socket connection.
pub fn IpcChannel::from_socket(conn : @socket.Connection) -> IpcChannel {
  Socket(conn)
}

///|
/// Create an IPC channel from a spawned child process.
///
/// The child must have been spawned with `pipe_stdin=true` and `pipe_stdout=true`.
/// Messages are sent to the child's stdin and read from its stdout,
/// using newline-delimited framing.
pub fn IpcChannel::from_child(child : @subprocess.ChildProcess) -> IpcChannel {
  Pipe(child)
}

///|
/// Send a string message over the channel.
///
/// - Socket: length-prefixed binary framing.
/// - Pipe: newline-delimited text (async).
pub async fn IpcChannel::send(
  self : IpcChannel,
  message : String,
) -> Unit raise @socket.IpcError {
  match self {
    Socket(conn) => conn.send(message)
    Pipe(child) =>
      match child.stdin {
        Some(writer) => {
          let data = message + "\n"
          writer.write(data) catch {
            e => raise @socket.IoError("Pipe write failed: " + e.to_string())
          }
        }
        None => raise @socket.IoError("Child process has no stdin pipe")
      }
  }
}

///|
/// Receive a string message from the channel.
///
/// - Socket: reads a length-prefixed message.
/// - Pipe: reads a newline-delimited line from stdout (async).
///
/// Returns `None` if the peer disconnected / EOF.
pub async fn IpcChannel::recv(
  self : IpcChannel,
) -> String? raise @socket.IpcError {
  match self {
    Socket(conn) => conn.recv()
    Pipe(child) =>
      match child.stdout {
        Some(reader) => {
          let line = reader.read_until("\n") catch { _ => None }
          match line {
            Some(s) => Some(s.trim(chars="\n").to_string())
            None => None
          }
        }
        None => raise @socket.IoError("Child process has no stdout pipe")
      }
  }
}

///|
/// Close the channel.
///
/// - Socket: closes the connection.
/// - Pipe: closes stdin (signals EOF to child).
pub fn IpcChannel::close(self : IpcChannel) -> Unit {
  match self {
    Socket(conn) => conn.close()
    Pipe(child) => child.close_stdin()
  }
}
