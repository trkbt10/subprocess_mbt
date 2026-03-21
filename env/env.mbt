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
#borrow(buffer)
extern "C" fn c_get_os_name(buffer : Bytes, buffer_len : Int) -> Int = "subprocess_env_get_os_name"

///|
#borrow(buffer)
extern "C" fn c_get_temp_dir(buffer : Bytes, buffer_len : Int) -> Int = "subprocess_env_get_temp_dir"
