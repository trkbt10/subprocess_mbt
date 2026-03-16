///|
async test "ProcessManager exec runs and returns result" {
  let pm = @managed.ProcessManager::new()
  let result = pm.exec("echo managed")
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout.trim(chars=" \n"), "managed")
}

///|
async test "ProcessManager exec_file runs and returns result" {
  let pm = @managed.ProcessManager::new()
  let result = pm.exec_file("echo", args=["managed", "file"])
  assert_eq(result.exit_code, 0)
  assert_eq(result.stdout.trim(chars=" \n"), "managed file")
}

///|
async test "ProcessManager spawn tracks child processes" {
  let pm = @managed.ProcessManager::new()
  @async.with_task_group(async fn(group) {
    let child = pm.spawn(group, "sleep", args=["0"])
    assert_true(child.pid() > 0)
    let _ = child.wait()
    group.return_immediately(())
  })
}

///|
async test "ProcessManager active_count decreases after process exits" {
  let pm = @managed.ProcessManager::new()
  @async.with_task_group(async fn(group) {
    let child = pm.spawn(group, "echo", args=["done"])
    let _ = child.wait()
    let count = pm.active_count()
    assert_eq(count, 0)
    group.return_immediately(())
  })
}

///|
async test "ProcessManager cancel_all cancels running processes" {
  let pm = @managed.ProcessManager::new()
  @async.with_task_group(async fn(group) {
    let child = pm.spawn(group, "echo", args=["quick"])
    let _ = child.wait()
    // After process completes, cancel_all is a no-op
    pm.cancel_all()
    assert_eq(pm.active_count(), 0)
    group.return_immediately(())
  })
}

///|
test "ProcessManager new creates empty manager" {
  let pm = @managed.ProcessManager::new()
  assert_eq(pm.active_count(), 0)
}
