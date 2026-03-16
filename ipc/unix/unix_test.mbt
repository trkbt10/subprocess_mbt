///|
test "UnixServer and UnixConnection basic send/recv" {
  let sock_path = "/tmp/subprocess_ipc_test_basic.sock"
  let server = @unix.UnixServer::new(sock_path)
  let client = @unix.UnixConnection::connect(sock_path)
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
test "UnixConnection send/recv empty message" {
  let sock_path = "/tmp/subprocess_ipc_test_empty.sock"
  let server = @unix.UnixServer::new(sock_path)
  let client = @unix.UnixConnection::connect(sock_path)
  let conn = server.accept()
  client.send("")
  let msg = conn.recv()
  assert_eq(msg, Some(""))
  client.close()
  conn.close()
  server.close()
}

///|
test "UnixConnection recv returns None on disconnect" {
  let sock_path = "/tmp/subprocess_ipc_test_eof.sock"
  let server = @unix.UnixServer::new(sock_path)
  let client = @unix.UnixConnection::connect(sock_path)
  let conn = server.accept()
  client.close()
  let msg = conn.recv()
  assert_eq(msg, None)
  conn.close()
  server.close()
}

///|
test "UnixConnection multiple messages" {
  let sock_path = "/tmp/subprocess_ipc_test_multi.sock"
  let server = @unix.UnixServer::new(sock_path)
  let client = @unix.UnixConnection::connect(sock_path)
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
test "UnixConnection raw bytes I/O" {
  let sock_path = "/tmp/subprocess_ipc_test_raw.sock"
  let server = @unix.UnixServer::new(sock_path)
  let client = @unix.UnixConnection::connect(sock_path)
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
test "UnixServer poll_accept returns None when no client" {
  let sock_path = "/tmp/subprocess_ipc_test_poll.sock"
  let server = @unix.UnixServer::new(sock_path)
  let result = server.poll_accept(timeout_ms=0)
  assert_true(result is None)
  server.close()
}

///|
test "UnixConnection peer_pid returns Some on local connection" {
  let sock_path = "/tmp/subprocess_ipc_test_pid.sock"
  let server = @unix.UnixServer::new(sock_path)
  let client = @unix.UnixConnection::connect(sock_path)
  let conn = server.accept()
  let pid = conn.peer_pid()
  assert_true(pid is Some(_))
  client.close()
  conn.close()
  server.close()
}

///|
test "UnixConnection poll returns true when data available" {
  let sock_path = "/tmp/subprocess_ipc_test_poll2.sock"
  let server = @unix.UnixServer::new(sock_path)
  let client = @unix.UnixConnection::connect(sock_path)
  let conn = server.accept()
  assert_eq(conn.poll(timeout_ms=0), false)
  client.send("data")
  assert_eq(conn.poll(timeout_ms=100), true)
  let _ = conn.recv()
  client.close()
  conn.close()
  server.close()
}
