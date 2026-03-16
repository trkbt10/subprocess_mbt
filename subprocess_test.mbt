///|
async test "exec runs shell command and captures stdout" {
  let result = @subprocess.exec("echo hello")
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout.trim(chars=" \n"), "hello")
}

///|
async test "exec captures stderr" {
  let result = @subprocess.exec("echo error >&2", check=false)
  assert_eq(result.exit_code, 0)
  assert_eq(result.stderr.trim(chars=" \n"), "error")
}

///|
async test "exec raises CommandFailed on non-zero exit" {
  let failed = try {
    let _ = @subprocess.exec("exit 42")
    false
  } catch {
    @subprocess.CommandFailed(result) => {
      assert_eq(result.exit_code, 42)
      true
    }
    _ => false
  }
  assert_true(failed)
}

///|
async test "exec with check=false does not raise on non-zero exit" {
  let result = @subprocess.exec("exit 1", check=false)
  assert_eq(result.exit_code, 1)
}

///|
async test "exec_file runs executable directly" {
  let result = @subprocess.exec_file("echo", args=["hello", "world"])
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout.trim(chars=" \n"), "hello world")
}

///|
async test "exec with cwd changes working directory" {
  let result = @subprocess.exec("pwd", cwd="/tmp")
  assert_true(result.stdout.contains("/tmp"))
}

///|
async test "exec with env sets environment variables" {
  let env = { "MY_TEST_VAR": "test_value" }
  let result = @subprocess.exec("echo $MY_TEST_VAR", env~)
  assert_eq(result.stdout.trim(chars=" \n"), "test_value")
}

///|
async test "spawn with pipe_stdout reads output" {
  @async.with_task_group(async fn(group) {
    let child = @subprocess.spawn(
      group,
      "echo",
      args=["spawned"],
      pipe_stdout=true,
    )
    let data = child.stdout.unwrap().read_all()
    let output = data.text()
    assert_eq(output.trim(chars=" \n"), "spawned")
    let exit_code = child.wait()
    assert_eq(exit_code, 0)
    group.return_immediately(())
  })
}

///|
async test "spawn with pipe_stdin and pipe_stdout for bidirectional I/O" {
  @async.with_task_group(async fn(group) {
    let child = @subprocess.spawn(
      group,
      "cat",
      pipe_stdin=true,
      pipe_stdout=true,
    )
    let stdin = child.stdin.unwrap()
    stdin.write("hello from test")
    stdin.close()
    let data = child.stdout.unwrap().read_all()
    let output = data.text()
    assert_eq(output, "hello from test")
    let exit_code = child.wait()
    assert_eq(exit_code, 0)
    group.return_immediately(())
  })
}

///|
async test "spawn_shell runs shell command" {
  @async.with_task_group(async fn(group) {
    let child = @subprocess.spawn_shell(
      group,
      "echo shell_spawn",
      pipe_stdout=true,
    )
    let data = child.stdout.unwrap().read_all()
    let output = data.text()
    assert_eq(output.trim(chars=" \n"), "shell_spawn")
    let exit_code = child.wait()
    assert_eq(exit_code, 0)
    group.return_immediately(())
  })
}

///|
async test "spawn pid returns valid process ID" {
  @async.with_task_group(async fn(group) {
    let child = @subprocess.spawn(group, "sleep", args=["0"])
    assert_true(child.pid() > 0)
    let _ = child.wait()
    group.return_immediately(())
  })
}
