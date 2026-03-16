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
test "get_env returns PATH" {
  // PATH exists on all platforms
  let path = @env.get_env("PATH")
  assert_true(path is Some(_))
}

///|
test "get_env returns None for nonexistent var" {
  let val = @env.get_env("SUBPROCESS_NONEXISTENT_VAR_12345")
  assert_true(val is None)
}
