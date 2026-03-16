///|
async fn main {
  // Example 1: exec - run a shell command
  println("=== exec ===")
  let result = @subprocess.exec("echo 'Hello from subprocess'")
  println("exit_code: " + result.exit_code.to_string())
  println("stdout: " + result.stdout)

  // Example 2: exec_file - run a file directly
  println("=== exec_file ===")
  let result2 = @subprocess.exec_file("uname", args=["-a"])
  println("exit_code: " + result2.exit_code.to_string())
  println("stdout: " + result2.stdout)

  // Example 3: spawn with streaming I/O
  println("=== spawn ===")
  @async.with_task_group(async fn(group) {
    let child = @subprocess.spawn(
      group,
      "cat",
      pipe_stdin=true,
      pipe_stdout=true,
    )
    // Write to child's stdin
    let stdin = child.stdin.unwrap()
    stdin.write("Hello from parent\n")
    stdin.close()
    // Read from child's stdout
    let data = child.stdout.unwrap().read_all()
    let output = data.text()
    println("child output: " + output)
    let exit_code = child.wait()
    println("child exit_code: " + exit_code.to_string())
    group.return_immediately(())
  })

  // Example 4: managed process pool
  println("=== managed ===")
  let pm = @managed.ProcessManager::new()
  let r = pm.exec("echo 'managed exec'")
  println("managed result: " + r.stdout)
  println("active count: " + pm.active_count().to_string())
}
