///|
/// Convert a FixedArray[Byte] to Bytes (first `len` elements).
fn fixed_to_bytes(arr : FixedArray[Byte], len : Int) -> Bytes {
  let a : Array[Byte] = Array::make(len, b'\x00')
  for i = 0; i < len; i = i + 1 {
    a[i] = arr[i]
  }
  Bytes::from_array(a)
}

///|
/// Send a length-prefixed message over a file descriptor.
/// Wire format: [4-byte big-endian length][payload bytes]
pub fn send_framed_message(fd : Int, data : Bytes) -> Unit raise IpcError {
  let len = data.length()
  if len > 64 * 1024 * 1024 {
    raise MessageTooLarge(len)
  }
  let total = 4 + len
  let buf_arr : Array[Byte] = Array::make(total, b'\x00')
  buf_arr[0] = ((len >> 24) & 0xFF).to_byte()
  buf_arr[1] = ((len >> 16) & 0xFF).to_byte()
  buf_arr[2] = ((len >> 8) & 0xFF).to_byte()
  buf_arr[3] = (len & 0xFF).to_byte()
  for i = 0; i < len; i = i + 1 {
    buf_arr[i + 4] = data[i]
  }
  let result = @ffi.write(fd, Bytes::from_array(buf_arr), total)
  if result < 0 {
    raise IoError("Failed to send message")
  }
}

///|
/// Receive a length-prefixed message from a file descriptor.
/// Returns `None` on EOF (peer disconnected).
pub fn recv_framed_message(fd : Int) -> String? raise IpcError {
  let header = FixedArray::make(4, b'\x00')
  let hdr_result = @ffi.read_exact(fd, header, 4)
  if hdr_result < 0 {
    return None
  }
  let msg_len = (header[0].to_int() << 24) |
    (header[1].to_int() << 16) |
    (header[2].to_int() << 8) |
    header[3].to_int()
  if msg_len == 0 {
    return Some("")
  }
  if msg_len < 0 || msg_len > 64 * 1024 * 1024 {
    raise MessageTooLarge(msg_len)
  }
  let payload = FixedArray::make(msg_len, b'\x00')
  let pay_result = @ffi.read_exact(fd, payload, msg_len)
  if pay_result < 0 {
    raise IoError("Short read: message truncated")
  }
  Some(@utf8.decode_lossy(fixed_to_bytes(payload, msg_len)))
}
