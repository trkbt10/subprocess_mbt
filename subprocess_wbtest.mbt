///|
#cfg(not(platform="windows"))
async test "exec_internal collects both stdout and stderr" {
  let result = exec_internal(
    "/bin/sh",
    ["-c", "echo out; echo err >&2"][:],
    cwd=None,
    env=Map::new(),
    do_inherit=true,
  )
  assert_eq(result.stdout.trim(chars=" \n"), "out")
  assert_eq(result.stderr.trim(chars=" \n"), "err")
}

///|
#cfg(not(platform="windows"))
async test "exec_internal with custom cwd" {
  let result = exec_internal(
    "/bin/sh",
    ["-c", "pwd"][:],
    cwd=Some("/tmp"),
    env=Map::new(),
    do_inherit=true,
  )
  assert_true(result.stdout.contains("/tmp"))
}

///|
#cfg(platform="windows")
async test "exec_internal collects stdout on windows" {
  let result = exec_internal(
    "cmd.exe",
    ["/c", "echo out"][:],
    cwd=None,
    env=Map::new(),
    do_inherit=true,
  )
  assert_true(result.stdout.contains("out"))
}
