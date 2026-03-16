///|
extern "C" fn c_ipc_socket_create() -> Int = "subprocess_ipc_socket_create"

///|
#borrow(path)
extern "C" fn c_ipc_socket_bind(fd : Int, path : Bytes, path_len : Int) -> Int = "subprocess_ipc_socket_bind"

///|
extern "C" fn c_ipc_socket_listen(fd : Int, backlog : Int) -> Int = "subprocess_ipc_socket_listen"

///|
extern "C" fn c_ipc_socket_accept(fd : Int) -> Int = "subprocess_ipc_socket_accept"

///|
#borrow(path)
extern "C" fn c_ipc_socket_connect(path : Bytes, path_len : Int) -> Int = "subprocess_ipc_socket_connect"

///|
extern "C" fn c_ipc_socket_close(fd : Int) = "subprocess_ipc_socket_close"

///|
#borrow(path)
extern "C" fn c_ipc_socket_unlink(path : Bytes, path_len : Int) -> Int = "subprocess_ipc_socket_unlink"

///|
#borrow(buf)
extern "C" fn c_ipc_read(
  fd : Int,
  buf : FixedArray[Byte],
  max_len : Int,
) -> Int = "subprocess_ipc_read"

///|
#borrow(buf)
extern "C" fn c_ipc_read_exact(
  fd : Int,
  buf : FixedArray[Byte],
  len : Int,
) -> Int = "subprocess_ipc_read_exact"

///|
#borrow(buf)
extern "C" fn c_ipc_write(fd : Int, buf : Bytes, len : Int) -> Int = "subprocess_ipc_write"

///|
extern "C" fn c_ipc_set_nonblocking(fd : Int) -> Int = "subprocess_ipc_set_nonblocking"

///|
extern "C" fn c_ipc_poll_read(fd : Int, timeout_ms : Int) -> Int = "subprocess_ipc_poll_read"

///|
extern "C" fn c_ipc_get_peer_pid(fd : Int) -> Int = "subprocess_ipc_get_peer_pid"
