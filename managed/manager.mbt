///|
/// A managed process pool that tracks all spawned child processes,
/// prevents zombie processes, and provides graceful shutdown.
///
/// All processes spawned through the manager are tracked and
/// automatically reaped when they terminate. On shutdown, all
/// remaining processes are cancelled and awaited.
pub struct ProcessManager {
  priv children : Array[ManagedChild]
}

///|
/// Internal tracking entry for a managed child process.
struct ManagedChild {
  child : @subprocess.ChildProcess
  mut completed : Bool
}

///|
/// Create a new ProcessManager.
pub fn ProcessManager::new() -> ProcessManager {
  { children: [] }
}

///|
/// Execute a shell command through the manager.
/// Synchronous exec calls are automatically tracked:
/// the process is awaited inline so no zombie can occur.
pub async fn ProcessManager::exec(
  _self : ProcessManager,
  command : String,
  cwd? : String,
  env? : Map[String, String],
  inherit_env? : Bool,
  check? : Bool,
) -> @subprocess.ExecResult raise @subprocess.SubprocessError {
  @subprocess.exec(command, cwd?, env?, inherit_env?, check?)
}

///|
/// Execute a file directly through the manager.
/// Synchronous exec calls are automatically tracked:
/// the process is awaited inline so no zombie can occur.
pub async fn ProcessManager::exec_file(
  _self : ProcessManager,
  file : String,
  args? : Array[String] = [],
  cwd? : String,
  env? : Map[String, String],
  inherit_env? : Bool,
  check? : Bool,
) -> @subprocess.ExecResult raise @subprocess.SubprocessError {
  @subprocess.exec_file(file, args~, cwd?, env?, inherit_env?, check?)
}

///|
/// Spawn a child process through the manager.
/// The process is tracked and will be cancelled on shutdown if still running.
pub async fn[X] ProcessManager::spawn(
  self : ProcessManager,
  group : @async.TaskGroup[X],
  command : String,
  args? : Array[String] = [],
  cwd? : String,
  env? : Map[String, String],
  inherit_env? : Bool,
  pipe_stdin? : Bool = false,
  pipe_stdout? : Bool = false,
  pipe_stderr? : Bool = false,
  cancel_handler? : @process.CancellationHandler,
) -> @subprocess.ChildProcess raise @subprocess.SubprocessError {
  let child = @subprocess.spawn(
    group,
    command,
    args~,
    cwd?,
    env?,
    inherit_env?,
    pipe_stdin~,
    pipe_stdout~,
    pipe_stderr~,
    cancel_handler?,
  )
  self.children.push({ child, completed: false })
  child
}

///|
/// Spawn a shell command through the manager.
/// The process is tracked and will be cancelled on shutdown if still running.
pub async fn[X] ProcessManager::spawn_shell(
  self : ProcessManager,
  group : @async.TaskGroup[X],
  command : String,
  cwd? : String,
  env? : Map[String, String],
  inherit_env? : Bool,
  pipe_stdin? : Bool = false,
  pipe_stdout? : Bool = false,
  pipe_stderr? : Bool = false,
  cancel_handler? : @process.CancellationHandler,
) -> @subprocess.ChildProcess raise @subprocess.SubprocessError {
  let child = @subprocess.spawn_shell(
    group,
    command,
    cwd?,
    env?,
    inherit_env?,
    pipe_stdin~,
    pipe_stdout~,
    pipe_stderr~,
    cancel_handler?,
  )
  self.children.push({ child, completed: false })
  child
}

///|
/// Reap completed child processes from the tracking list.
/// This is called automatically but can be called manually to free resources.
pub fn ProcessManager::reap(self : ProcessManager) -> Unit {
  let to_remove : Array[Int] = []
  for i, entry in self.children {
    if not(entry.completed) {
      let status = entry.child.try_wait() catch { _ => None }
      match status {
        Some(_) => {
          entry.completed = true
          to_remove.push(i)
        }
        None => ()
      }
    } else {
      to_remove.push(i)
    }
  }
  // Remove completed entries in reverse order to preserve indices
  for j = to_remove.length() - 1; j >= 0; j = j - 1 {
    let _ = self.children.remove(to_remove[j])
  }
}

///|
/// Get the number of currently active (non-completed) child processes.
pub fn ProcessManager::active_count(self : ProcessManager) -> Int {
  self.reap()
  self.children.length()
}

///|
/// Cancel all running child processes.
/// Does not wait for them to actually terminate.
pub fn ProcessManager::cancel_all(self : ProcessManager) -> Unit {
  for entry in self.children {
    if not(entry.completed) {
      entry.child.cancel()
    }
  }
}

///|
/// Gracefully shut down all managed processes.
/// First cancels all running processes, then waits for them to terminate.
/// This ensures no zombie processes are left behind.
pub async fn ProcessManager::shutdown(self : ProcessManager) -> Unit {
  self.cancel_all()
  for entry in self.children {
    if not(entry.completed) {
      let _ = entry.child.wait()
      entry.completed = true
    }
  }
  self.children.clear()
}

///|
/// Wait for all managed processes to complete naturally (without cancelling).
/// Blocks until every tracked process has exited.
pub async fn ProcessManager::wait_all(self : ProcessManager) -> Unit {
  for entry in self.children {
    if not(entry.completed) {
      let _ = entry.child.wait()
      entry.completed = true
    }
  }
  self.children.clear()
}
