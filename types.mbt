///|
/// Result of executing a subprocess command.
/// Contains the exit code and captured stdout/stderr output.
pub(all) struct ExecResult {
  exit_code : Int
  stdout : String
  stderr : String
}

///|
pub impl Show for ExecResult with output(self, logger) {
  logger.write_string("ExecResult { exit_code: ")
  logger.write_string(self.exit_code.to_string())
  logger.write_string(", stdout: \"")
  logger.write_string(self.stdout)
  logger.write_string("\", stderr: \"")
  logger.write_string(self.stderr)
  logger.write_string("\" }")
}

///|
/// Error type for subprocess operations.
pub(all) suberror SubprocessError {
  /// The command exited with a non-zero exit code.
  CommandFailed(ExecResult)
  /// Failed to spawn the process.
  SpawnFailed(String)
}

///|
pub impl Show for SubprocessError with output(self, logger) {
  match self {
    CommandFailed(result) => {
      logger.write_string("CommandFailed(")
      result.output(logger)
      logger.write_string(")")
    }
    SpawnFailed(msg) => {
      logger.write_string("SpawnFailed(\"")
      logger.write_string(msg)
      logger.write_string("\")")
    }
  }
}

///|
/// A handle to a spawned child process with streaming I/O.
pub struct ChildProcess {
  /// The underlying process handle.
  process : @process.Process
  /// Writer for sending data to the child's stdin.
  stdin : @process.WriteToProcess?
  /// Reader for receiving data from the child's stdout.
  stdout : @process.ReadFromProcess?
  /// Reader for receiving data from the child's stderr.
  stderr : @process.ReadFromProcess?
}
