///|
/// Windows shell command construction.
#cfg(platform="windows")
fn shell_command(command : String) -> (String, Array[String]) {
  ("cmd.exe", ["/c", command])
}
