///|
pub extern "C" fn socket_create() -> Int = "subprocess_ipc_socket_create"

///|
#borrow(path)
pub extern "C" fn socket_bind(fd : Int, path : Bytes, path_len : Int) -> Int = "subprocess_ipc_socket_bind"

///|
pub extern "C" fn socket_listen(fd : Int, backlog : Int) -> Int = "subprocess_ipc_socket_listen"

///|
pub extern "C" fn socket_accept(fd : Int) -> Int = "subprocess_ipc_socket_accept"

///|
#borrow(path)
pub extern "C" fn socket_connect(path : Bytes, path_len : Int) -> Int = "subprocess_ipc_socket_connect"

///|
pub extern "C" fn socket_close(fd : Int) = "subprocess_ipc_socket_close"

///|
#borrow(path)
pub extern "C" fn socket_unlink(path : Bytes, path_len : Int) -> Int = "subprocess_ipc_socket_unlink"

///|
#borrow(buf)
pub extern "C" fn read(fd : Int, buf : FixedArray[Byte], max_len : Int) -> Int = "subprocess_ipc_read"

///|
#borrow(buf)
pub extern "C" fn read_exact(
  fd : Int,
  buf : FixedArray[Byte],
  len : Int,
) -> Int = "subprocess_ipc_read_exact"

///|
#borrow(buf)
pub extern "C" fn write(fd : Int, buf : Bytes, len : Int) -> Int = "subprocess_ipc_write"

///|
pub extern "C" fn set_nonblocking(fd : Int) -> Int = "subprocess_ipc_set_nonblocking"

///|
pub extern "C" fn poll_read(fd : Int, timeout_ms : Int) -> Int = "subprocess_ipc_poll_read"

///|
pub extern "C" fn get_peer_pid(fd : Int) -> Int = "subprocess_ipc_get_peer_pid"
