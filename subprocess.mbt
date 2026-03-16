///|
/// Execute a shell command and collect its output.
/// On Unix, the command is run through `/bin/sh -c`.
/// On Windows, the command is run through `cmd.exe /c`.
///
/// Returns `ExecResult` with exit code, stdout, and stderr.
/// Raises `SubprocessError::CommandFailed` if the exit code is non-zero
/// and `check` is true (default).
pub async fn exec(
  command : String,
  cwd? : String,
  env? : Map[String, String],
  inherit_env? : Bool,
  check? : Bool,
) -> ExecResult raise SubprocessError {
  let cwd = cwd
  let env = env.unwrap_or(Map::new())
  let do_inherit = inherit_env.unwrap_or(true)
  let check = check.unwrap_or(true)
  let (shell, args) = shell_command(command)
  let result = exec_internal(shell, args[:], cwd~, env~, do_inherit~) catch {
    e => raise SpawnFailed(e.to_string())
  }
  if check && result.exit_code != 0 {
    raise CommandFailed(result)
  }
  result
}

///|
/// Execute a file directly without going through a shell.
/// The file is executed with the given arguments.
///
/// Returns `ExecResult` with exit code, stdout, and stderr.
/// Raises `SubprocessError::CommandFailed` if the exit code is non-zero
/// and `check` is true (default).
pub async fn exec_file(
  file : String,
  args? : Array[String] = [],
  cwd? : String,
  env? : Map[String, String],
  inherit_env? : Bool,
  check? : Bool,
) -> ExecResult raise SubprocessError {
  let cwd = cwd
  let env = env.unwrap_or(Map::new())
  let do_inherit = inherit_env.unwrap_or(true)
  let check = check.unwrap_or(true)
  let cmd : StringView = file
  let result = exec_internal(cmd, args[:], cwd~, env~, do_inherit~) catch {
    e => raise SpawnFailed(e.to_string())
  }
  if check && result.exit_code != 0 {
    raise CommandFailed(result)
  }
  result
}

///|
/// Internal helper to run a process and collect output.
async fn exec_internal(
  cmd : StringView,
  args : ArrayView[String],
  cwd~ : String?,
  env~ : Map[String, String],
  do_inherit~ : Bool,
) -> ExecResult {
  let cwd_view : StringView? = match cwd {
    Some(s) => Some(s)
    None => None
  }
  let (exit_code, stdout_data, stderr_data) = match cwd_view {
    Some(c) =>
      @process.collect_output(
        cmd,
        args,
        extra_env=env,
        inherit_env=do_inherit,
        cwd=c,
      )
    None =>
      @process.collect_output(cmd, args, extra_env=env, inherit_env=do_inherit)
  }
  let stdout_str = stdout_data.text() catch { _ => "" }
  let stderr_str = stderr_data.text() catch { _ => "" }
  { exit_code, stdout: stdout_str, stderr: stderr_str }
}
