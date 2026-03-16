///|
/// An IPC socket server (AF_UNIX) that listens for incoming connections.
///
/// The server binds to a filesystem path and accepts connections
/// from `Connection::connect()`.
pub struct Server {
  priv fd : Int
  priv path : String
}

///|
/// Create a new IPC socket server bound to the given path.
///
/// The socket file is automatically created at the path.
/// Any existing socket file at the same path is removed first.
pub fn Server::new(path : String) -> Server raise IpcError {
  let fd = c_ipc_socket_create()
  if fd < 0 {
    raise SocketError("Failed to create Unix socket")
  }
  let path_bytes = string_to_utf8(path)
  if c_ipc_socket_bind(fd, path_bytes, path_bytes.length()) < 0 {
    c_ipc_socket_close(fd)
    raise SocketError("Failed to bind to path: " + path)
  }
  if c_ipc_socket_listen(fd, 16) < 0 {
    c_ipc_socket_close(fd)
    raise SocketError("Failed to listen on: " + path)
  }
  { fd, path }
}

///|
/// Accept an incoming connection. Blocks until a client connects.
///
/// Returns a `Connection` representing the accepted client.
pub fn Server::accept(self : Server) -> Connection raise IpcError {
  let client_fd = c_ipc_socket_accept(self.fd)
  if client_fd < 0 {
    raise IoError("Failed to accept connection")
  }
  Connection::from_fd(client_fd)
}

///|
/// Poll for an incoming connection without blocking.
///
/// `timeout_ms`: -1 = block forever, 0 = non-blocking, >0 = timeout in ms.
/// Returns `Some(connection)` if a client connected, `None` on timeout.
pub fn Server::poll_accept(
  self : Server,
  timeout_ms? : Int = 0,
) -> Connection? raise IpcError {
  let ready = c_ipc_poll_read(self.fd, timeout_ms)
  if ready < 0 {
    raise IoError("Failed to poll for connections")
  }
  if ready == 0 {
    return None
  }
  Some(self.accept())
}

///|
/// Close the server and remove the socket file.
pub fn Server::close(self : Server) -> Unit {
  c_ipc_socket_close(self.fd)
  let path_bytes = string_to_utf8(self.path)
  let _ = c_ipc_socket_unlink(path_bytes, path_bytes.length())
}

///|
/// Get the file descriptor of the server socket.
pub fn Server::fd(self : Server) -> Int {
  self.fd
}

///|
/// Get the path the server is bound to.
pub fn Server::path(self : Server) -> String {
  self.path
}

///|
/// Set the server socket to non-blocking mode.
pub fn Server::set_nonblocking(self : Server) -> Unit raise IpcError {
  if c_ipc_set_nonblocking(self.fd) < 0 {
    raise SocketError("Failed to set non-blocking mode")
  }
}
