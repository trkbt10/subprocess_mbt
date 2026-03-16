///|
/// Error type for IPC socket operations.
pub(all) suberror IpcError {
  /// Socket creation or bind failed.
  SocketError(String)
  /// Connection to server failed.
  ConnectionFailed(String)
  /// Read/write operation failed.
  IoError(String)
  /// Peer disconnected.
  Disconnected
  /// Message too large (exceeds 64MB limit).
  MessageTooLarge(Int)
}

///|
pub impl Show for IpcError with output(self, logger) {
  match self {
    SocketError(msg) => {
      logger.write_string("IpcError::SocketError(\"")
      logger.write_string(msg)
      logger.write_string("\")")
    }
    ConnectionFailed(msg) => {
      logger.write_string("IpcError::ConnectionFailed(\"")
      logger.write_string(msg)
      logger.write_string("\")")
    }
    IoError(msg) => {
      logger.write_string("IpcError::IoError(\"")
      logger.write_string(msg)
      logger.write_string("\")")
    }
    Disconnected => logger.write_string("IpcError::Disconnected")
    MessageTooLarge(size) => {
      logger.write_string("IpcError::MessageTooLarge(")
      logger.write_string(size.to_string())
      logger.write_string(")")
    }
  }
}
