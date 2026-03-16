///|
/// Platform environment detection and directory resolution.

///|
/// OS kind enumeration.
pub(all) enum OsKind {
  Linux
  MacOS
  Windows
  Unknown
}

///|
/// Detect the current operating system.
pub fn detect_os() -> OsKind {
  let buffer = Bytes::new(64)
  let len = c_get_os_name(buffer, 64)
  if len <= 0 {
    return Unknown
  }
  let name = @utf8.decode_lossy(buffer[:len])
  if name == "Darwin" {
    MacOS
  } else if name == "Linux" {
    Linux
  } else if name.contains("Windows") ||
    name.contains("MINGW") ||
    name.contains("MSYS") {
    Windows
  } else {
    Unknown
  }
}

///|
/// Get an environment variable by name.
/// Returns `None` if the variable is not set.
pub fn get_env(name : String) -> String? {
  let buffer = Bytes::new(4096)
  let name_bytes = to_utf8_cstring(name)
  let len = c_getenv(name_bytes, buffer, 4096)
  if len <= 0 {
    return None
  }
  Some(@utf8.decode_lossy(buffer[:len]))
}

///|
/// Get the OS standard temporary directory.
/// - Unix: `$TMPDIR` or `/tmp`
/// - Windows: `GetTempPathA` or `%TEMP%` or `C:\Windows\Temp`
pub fn temp_dir() -> String {
  let buffer = Bytes::new(1024)
  let len = c_get_temp_dir(buffer, 1024)
  if len <= 0 {
    return "/tmp"
  }
  @utf8.decode_lossy(buffer[:len])
}

///|
/// Get a named subdirectory under the OS temp directory.
pub fn temp_dir_for(name : String) -> String {
  let sep = match detect_os() {
    Windows => "\\"
    _ => "/"
  }
  temp_dir() + sep + name
}

///|
/// Encode a MoonBit string to null-terminated UTF-8 bytes for C FFI calls.
fn to_utf8_cstring(s : String) -> Bytes {
  let utf8 = @utf8.encode(s)
  let len = utf8.length()
  Bytes::makei(len + 1, fn(i) { if i < len { utf8[i] } else { b'\x00' } })
}

///|
#borrow(buffer)
extern "C" fn c_get_os_name(buffer : Bytes, buffer_len : Int) -> Int = "subprocess_env_get_os_name"

///|
#borrow(name, buffer)
extern "C" fn c_getenv(name : Bytes, buffer : Bytes, buffer_len : Int) -> Int = "subprocess_env_getenv"

///|
#borrow(buffer)
extern "C" fn c_get_temp_dir(buffer : Bytes, buffer_len : Int) -> Int = "subprocess_env_get_temp_dir"
