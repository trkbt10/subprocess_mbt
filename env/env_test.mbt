///|
test "detect_os returns known OS" {
  let os = @env.detect_os()
  assert_true(
    match os {
      Linux | MacOS | Windows => true
      _ => false
    },
  )
}

///|
test "temp_dir returns non-empty string" {
  let dir = @env.temp_dir()
  assert_true(dir.length() > 0)
}

///|
test "temp_dir_for appends name" {
  let dir = @env.temp_dir_for("subprocess-test")
  assert_true(dir.contains("subprocess-test"))
}

///|
#cfg(not(platform="windows"))
test "get_env returns value for existing var (unix)" {
  let path = @env.get_env("PATH")
  assert_true(path is Some(_))
}

///|
#cfg(platform="windows")
test "get_env returns value for existing var (windows)" {
  // WINDIR is always set on Windows (e.g. C:\Windows)
  let windir = @env.get_env("WINDIR")
  assert_true(windir is Some(_))
}

///|
test "get_env returns None for nonexistent var" {
  let val = @env.get_env("SUBPROCESS_NONEXISTENT_VAR_12345")
  assert_true(val is None)
}
