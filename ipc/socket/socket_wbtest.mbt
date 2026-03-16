///|
#cfg(not(platform="windows"))
test "send_framed_message and recv_framed_message roundtrip" {
  let sock_path = @env.temp_dir() + "/subprocess_ipc_wbtest_frame.sock"
  let server_fd = @ffi.socket_create()
  assert_true(server_fd >= 0)
  let path_bytes = @utf8.encode(sock_path)
  assert_eq(@ffi.socket_bind(server_fd, path_bytes, path_bytes.length()), 0)
  assert_eq(@ffi.socket_listen(server_fd, 1), 0)
  let client_fd = @ffi.socket_connect(path_bytes, path_bytes.length())
  assert_true(client_fd >= 0)
  let conn_fd = @ffi.socket_accept(server_fd)
  assert_true(conn_fd >= 0)
  send_framed_message(client_fd, @utf8.encode("test message"))
  let result = recv_framed_message(conn_fd)
  assert_eq(result, Some("test message"))
  @ffi.socket_close(client_fd)
  @ffi.socket_close(conn_fd)
  @ffi.socket_close(server_fd)
  let _ = @ffi.socket_unlink(path_bytes, path_bytes.length())
}

///|
test "fixed_to_bytes converts correctly" {
  let arr : FixedArray[Byte] = [b'\x41', b'\x42', b'\x43', b'\x00']
  let bytes = fixed_to_bytes(arr, 3)
  assert_eq(bytes.length(), 3)
  assert_eq(bytes[0], b'\x41')
  assert_eq(bytes[1], b'\x42')
  assert_eq(bytes[2], b'\x43')
}
