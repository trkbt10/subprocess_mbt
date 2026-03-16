///|
/// Unix shell command construction.
#cfg(not(platform="windows"))
fn shell_command(command : String) -> (String, Array[String]) {
  ("/bin/sh", ["-c", command])
}
