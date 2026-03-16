///|
/// Spawn a child process within a task group, with streaming I/O access.
///
/// Returns a `ChildProcess` handle with optional stdin writer,
/// stdout reader, and stderr reader for streaming communication.
///
/// The `pipe_stdin`, `pipe_stdout`, `pipe_stderr` parameters control
/// whether pipes are created for each stream.
pub async fn[X] spawn(
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
) -> ChildProcess raise SubprocessError {
  let env = env.unwrap_or(Map::new())
  let do_inherit = inherit_env.unwrap_or(true)
  let cmd : StringView = command
  // Set up pipes
  let (stdin_for_process, stdin_writer) = if pipe_stdin {
    let (input, writer) = @process.write_to_process() catch {
      e => raise SpawnFailed("Failed to create stdin pipe: " + e.to_string())
    }
    (Some(input), Some(writer))
  } else {
    (None, None)
  }
  let (stdout_reader, stdout_for_process) = if pipe_stdout {
    let (reader, output) = @process.read_from_process() catch {
      e => raise SpawnFailed("Failed to create stdout pipe: " + e.to_string())
    }
    (Some(reader), Some(output))
  } else {
    (None, None)
  }
  let (stderr_reader, stderr_for_process) = if pipe_stderr {
    let (reader, output) = @process.read_from_process() catch {
      e => raise SpawnFailed("Failed to create stderr pipe: " + e.to_string())
    }
    (Some(reader), Some(output))
  } else {
    (None, None)
  }
  // Build spawn call
  let cwd_view : StringView? = match cwd {
    Some(s) => Some(s)
    None => None
  }
  let process = spawn_with_options(
    group,
    cmd,
    args[:],
    cwd=cwd_view,
    env~,
    do_inherit~,
    stdin=stdin_for_process,
    stdout=stdout_for_process,
    stderr=stderr_for_process,
    cancel_handler?,
  ) catch {
    e => raise SpawnFailed("Failed to spawn process: " + e.to_string())
  }
  { process, stdin: stdin_writer, stdout: stdout_reader, stderr: stderr_reader }
}

///|
/// Spawn a shell command within a task group, with streaming I/O access.
/// The command is run through `/bin/sh -c`.
pub async fn[X] spawn_shell(
  group : @async.TaskGroup[X],
  command : String,
  cwd? : String,
  env? : Map[String, String],
  inherit_env? : Bool,
  pipe_stdin? : Bool = false,
  pipe_stdout? : Bool = false,
  pipe_stderr? : Bool = false,
  cancel_handler? : @process.CancellationHandler,
) -> ChildProcess raise SubprocessError {
  spawn(
    group,
    "/bin/sh",
    args=["-c", command],
    cwd?,
    env?,
    inherit_env?,
    pipe_stdin~,
    pipe_stdout~,
    pipe_stderr~,
    cancel_handler?,
  )
}

///|
async fn[X] spawn_with_options(
  group : @async.TaskGroup[X],
  cmd : StringView,
  args : ArrayView[String],
  cwd~ : StringView?,
  env~ : Map[String, String],
  do_inherit~ : Bool,
  stdin~ : &@process.ProcessInput?,
  stdout~ : &@process.ProcessOutput?,
  stderr~ : &@process.ProcessOutput?,
  cancel_handler? : @process.CancellationHandler,
) -> @process.Process {
  match (cwd, stdin, stdout, stderr, cancel_handler) {
    (Some(c), Some(si), Some(so), Some(se), Some(ch)) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stdout=so,
        stderr=se,
        cwd=c,
        cancel_handler=ch,
      )
    (Some(c), Some(si), Some(so), Some(se), None) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stdout=so,
        stderr=se,
        cwd=c,
      )
    (Some(c), Some(si), Some(so), None, _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stdout=so,
        cwd=c,
      )
    (Some(c), Some(si), None, Some(se), _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stderr=se,
        cwd=c,
      )
    (Some(c), None, Some(so), Some(se), _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdout=so,
        stderr=se,
        cwd=c,
      )
    (Some(c), Some(si), None, None, _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        cwd=c,
      )
    (Some(c), None, Some(so), None, _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdout=so,
        cwd=c,
      )
    (Some(c), None, None, Some(se), _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stderr=se,
        cwd=c,
      )
    (Some(c), None, None, None, _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        cwd=c,
      )
    (None, Some(si), Some(so), Some(se), Some(ch)) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stdout=so,
        stderr=se,
        cancel_handler=ch,
      )
    (None, Some(si), Some(so), Some(se), None) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stdout=so,
        stderr=se,
      )
    (None, Some(si), Some(so), None, _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stdout=so,
      )
    (None, Some(si), None, Some(se), _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
        stderr=se,
      )
    (None, None, Some(so), Some(se), _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdout=so,
        stderr=se,
      )
    (None, Some(si), None, None, _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdin=si,
      )
    (None, None, Some(so), None, _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stdout=so,
      )
    (None, None, None, Some(se), _) =>
      @process.spawn(
        group,
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        stderr=se,
      )
    (None, None, None, None, _) =>
      @process.spawn(group, cmd, args, extra_env=env, inherit_env=do_inherit)
  }
}

///|
/// Wait for the child process to terminate and return its exit code.
pub async fn ChildProcess::wait(self : ChildProcess) -> Int {
  self.process.wait()
}

///|
/// Try to get the exit code without blocking.
/// Returns `Some(exit_code)` if the process has terminated, `None` if still running.
pub fn ChildProcess::try_wait(self : ChildProcess) -> Int? raise {
  self.process.try_wait()
}

///|
/// Cancel the child process using its cancellation handler.
pub fn ChildProcess::cancel(self : ChildProcess) -> Unit {
  self.process.cancel()
}

///|
/// Get the process ID of the child process.
pub fn ChildProcess::pid(self : ChildProcess) -> Int {
  self.process.pid
}

///|
/// Close the stdin writer, signaling EOF to the child process.
pub fn ChildProcess::close_stdin(self : ChildProcess) -> Unit {
  match self.stdin {
    Some(writer) => writer.close()
    None => ()
  }
}
