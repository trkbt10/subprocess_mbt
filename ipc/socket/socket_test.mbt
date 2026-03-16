///|
/// Helper to create a unique socket path under the OS temp directory.
#cfg(not(platform="windows"))
fn test_sock_path(name : String) -> String {
  @env.temp_dir() + "/subprocess_ipc_test_" + name + ".sock"
}

///|
#cfg(not(platform="windows"))
test "Server and Connection basic send/recv" {
  let sock_path = test_sock_path("basic")
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  client.send("hello server")
  let msg = conn.recv()
  assert_eq(msg, Some("hello server"))
  conn.send("hello client")
  let msg2 = client.recv()
  assert_eq(msg2, Some("hello client"))
  client.close()
  conn.close()
  server.close()
}

///|
#cfg(not(platform="windows"))
test "Connection send/recv empty message" {
  let sock_path = test_sock_path("empty")
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  client.send("")
  let msg = conn.recv()
  assert_eq(msg, Some(""))
  client.close()
  conn.close()
  server.close()
}

///|
#cfg(not(platform="windows"))
test "Connection recv returns None on disconnect" {
  let sock_path = test_sock_path("eof")
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  client.close()
  let msg = conn.recv()
  assert_eq(msg, None)
  conn.close()
  server.close()
}

///|
#cfg(not(platform="windows"))
test "Connection multiple messages" {
  let sock_path = test_sock_path("multi")
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  client.send("msg1")
  client.send("msg2")
  client.send("msg3")
  assert_eq(conn.recv(), Some("msg1"))
  assert_eq(conn.recv(), Some("msg2"))
  assert_eq(conn.recv(), Some("msg3"))
  client.close()
  conn.close()
  server.close()
}

///|
#cfg(not(platform="windows"))
test "Connection raw bytes I/O" {
  let sock_path = test_sock_path("raw")
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  let data : Array[Byte] = [b'\x01', b'\x02', b'\x03']
  client.write_bytes(Bytes::from_array(data))
  let received = conn.read_bytes(max_len=10)
  assert_eq(received.length(), 3)
  assert_eq(received[0], b'\x01')
  assert_eq(received[1], b'\x02')
  assert_eq(received[2], b'\x03')
  client.close()
  conn.close()
  server.close()
}

///|
#cfg(not(platform="windows"))
test "Server poll_accept returns None when no client" {
  let sock_path = test_sock_path("poll")
  let server = @socket.Server::new(sock_path)
  let result = server.poll_accept(timeout_ms=0)
  assert_true(result is None)
  server.close()
}

///|
#cfg(not(platform="windows"))
test "Connection peer_pid returns Some on local connection" {
  let sock_path = test_sock_path("pid")
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  let pid = conn.peer_pid()
  assert_true(pid is Some(_))
  client.close()
  conn.close()
  server.close()
}

///|
#cfg(not(platform="windows"))
test "Connection poll returns true when data available" {
  let sock_path = test_sock_path("poll2")
  let server = @socket.Server::new(sock_path)
  let client = @socket.Connection::connect(sock_path)
  let conn = server.accept()
  assert_eq(conn.poll(timeout_ms=0), false)
  client.send("data")
  assert_eq(conn.poll(timeout_ms=100), true)
  let _ = conn.recv()
  client.close()
  conn.close()
  server.close()
}
