// Common function signatures for subprocess IPC FFI.
// Platform implementations: unix.c, windows.c

#ifndef SUBPROCESS_IPC_H
#define SUBPROCESS_IPC_H

// Socket lifecycle
int subprocess_ipc_socket_create(void);
int subprocess_ipc_socket_bind(int fd, const unsigned char *path_bytes, int path_len);
int subprocess_ipc_socket_listen(int fd, int backlog);
int subprocess_ipc_socket_accept(int fd);
int subprocess_ipc_socket_connect(const unsigned char *path_bytes, int path_len);
void subprocess_ipc_socket_close(int fd);
int subprocess_ipc_socket_unlink(const unsigned char *path_bytes, int path_len);

// I/O
int subprocess_ipc_read(int fd, unsigned char *buf, int max_len);
int subprocess_ipc_write(int fd, const unsigned char *buf, int len);
int subprocess_ipc_read_exact(int fd, unsigned char *buf, int len);

// Non-blocking / polling
int subprocess_ipc_set_nonblocking(int fd);
int subprocess_ipc_poll_read(int fd, int timeout_ms);

// Utility
int subprocess_ipc_get_peer_pid(int fd);

#endif // SUBPROCESS_IPC_H
