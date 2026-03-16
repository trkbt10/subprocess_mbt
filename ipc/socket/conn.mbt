///|
/// A connection to an IPC socket, either from client `connect()`
/// or from server `accept()`.
///
/// Supports both raw byte I/O and length-prefixed message framing.
pub struct Connection {
  priv fd : Int
}

///|
/// Create a Connection wrapping an existing file descriptor.
pub fn Connection::from_fd(fd : Int) -> Connection {
  { fd, }
}

///|
/// Connect to an IPC socket server at the given path.
pub fn Connection::connect(path : String) -> Connection raise IpcError {
  let path_bytes = string_to_utf8(path)
  let fd = @ffi.socket_connect(path_bytes, path_bytes.length())
  if fd < 0 {
    raise ConnectionFailed("Failed to connect to: " + path)
  }
  { fd, }
}

///|
/// Send a length-prefixed message (UTF-8 string).
///
/// Wire format: `[4-byte big-endian length][payload bytes]`
pub fn Connection::send(
  self : Connection,
  message : String,
) -> Unit raise IpcError {
  let data = string_to_utf8(message)
  send_framed_message(self.fd, data)
}

///|
/// Receive a length-prefixed message (UTF-8 string).
///
/// Blocks until a complete message is received.
/// Returns `None` if the peer disconnected cleanly.
pub fn Connection::recv(self : Connection) -> String? raise IpcError {
  recv_framed_message(self.fd)
}

///|
/// Send raw bytes over the connection.
pub fn Connection::write_bytes(
  self : Connection,
  data : Bytes,
) -> Unit raise IpcError {
  let result = @ffi.write(self.fd, data, data.length())
  if result < 0 {
    raise IoError("Failed to write bytes")
  }
}

///|
/// Read raw bytes from the connection.
///
/// Returns up to `max_len` bytes, or fewer if less data is available.
/// Returns empty Bytes on EOF.
pub fn Connection::read_bytes(
  self : Connection,
  max_len? : Int = 4096,
) -> Bytes raise IpcError {
  let buf = FixedArray::make(max_len, b'\x00')
  let n = @ffi.read(self.fd, buf, max_len)
  if n < 0 {
    raise IoError("Failed to read bytes")
  }
  if n == 0 {
    return Bytes::new(0)
  }
  fixed_to_bytes(buf, n)
}

///|
/// Close the connection.
pub fn Connection::close(self : Connection) -> Unit {
  @ffi.socket_close(self.fd)
}

///|
/// Get the file descriptor of the connection.
pub fn Connection::fd(self : Connection) -> Int {
  self.fd
}

///|
/// Get the PID of the process on the other end of the connection.
/// Returns `None` if the peer PID cannot be determined.
/// Supported on macOS (LOCAL_PEERPID) and Linux (SO_PEERCRED).
pub fn Connection::peer_pid(self : Connection) -> Int? {
  let pid = @ffi.get_peer_pid(self.fd)
  if pid > 0 {
    Some(pid)
  } else {
    None
  }
}

///|
/// Poll the connection for data readiness.
///
/// `timeout_ms`: -1 = block forever, 0 = non-blocking, >0 = timeout in ms.
/// Returns `true` if data is available to read.
pub fn Connection::poll(
  self : Connection,
  timeout_ms? : Int = 0,
) -> Bool raise IpcError {
  let ready = @ffi.poll_read(self.fd, timeout_ms)
  if ready < 0 {
    raise IoError("Failed to poll connection")
  }
  ready > 0
}
