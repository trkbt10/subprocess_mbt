///|
/// A connection to a Unix domain socket, either from client `connect()`
/// or from server `accept()`.
///
/// Supports both raw byte I/O and length-prefixed message framing.
pub struct UnixConnection {
  priv fd : Int
}

///|
/// Create a UnixConnection wrapping an existing file descriptor.
pub fn UnixConnection::from_fd(fd : Int) -> UnixConnection {
  { fd, }
}

///|
/// Connect to a Unix domain socket server at the given path.
pub fn UnixConnection::connect(path : String) -> UnixConnection raise IpcError {
  let path_bytes = string_to_utf8(path)
  let fd = c_ipc_socket_connect(path_bytes, path_bytes.length())
  if fd < 0 {
    raise ConnectionFailed("Failed to connect to: " + path)
  }
  { fd, }
}

///|
/// Send a length-prefixed message (UTF-8 string).
///
/// Wire format: `[4-byte big-endian length][payload bytes]`
pub fn UnixConnection::send(
  self : UnixConnection,
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
pub fn UnixConnection::recv(self : UnixConnection) -> String? raise IpcError {
  recv_framed_message(self.fd)
}

///|
/// Send raw bytes over the connection.
pub fn UnixConnection::write_bytes(
  self : UnixConnection,
  data : Bytes,
) -> Unit raise IpcError {
  let result = c_ipc_write(self.fd, data, data.length())
  if result < 0 {
    raise IoError("Failed to write bytes")
  }
}

///|
/// Read raw bytes from the connection.
///
/// Returns up to `max_len` bytes, or fewer if less data is available.
/// Returns empty Bytes on EOF.
pub fn UnixConnection::read_bytes(
  self : UnixConnection,
  max_len? : Int = 4096,
) -> Bytes raise IpcError {
  let buf = FixedArray::make(max_len, b'\x00')
  let n = c_ipc_read(self.fd, buf, max_len)
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
pub fn UnixConnection::close(self : UnixConnection) -> Unit {
  c_ipc_socket_close(self.fd)
}

///|
/// Get the file descriptor of the connection.
pub fn UnixConnection::fd(self : UnixConnection) -> Int {
  self.fd
}

///|
/// Get the PID of the process on the other end of the connection.
/// Returns `None` if the peer PID cannot be determined.
/// Supported on macOS (LOCAL_PEERPID) and Linux (SO_PEERCRED).
pub fn UnixConnection::peer_pid(self : UnixConnection) -> Int? {
  let pid = c_ipc_get_peer_pid(self.fd)
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
pub fn UnixConnection::poll(
  self : UnixConnection,
  timeout_ms? : Int = 0,
) -> Bool raise IpcError {
  let ready = c_ipc_poll_read(self.fd, timeout_ms)
  if ready < 0 {
    raise IoError("Failed to poll connection")
  }
  ready > 0
}
