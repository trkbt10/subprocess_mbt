// POSIX AF_UNIX implementation (Linux, macOS, BSD)

#ifdef __linux__
#define _GNU_SOURCE
#endif

#ifndef _WIN32

#include "ipc.h"

#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <fcntl.h>
#include <poll.h>
#include <string.h>
#include <errno.h>

#ifdef __APPLE__
#include <sys/ucred.h>
#endif

// ---------- Socket lifecycle ----------

int subprocess_ipc_socket_create(void) {
  int fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd < 0) return -1;
  return fd;
}

int subprocess_ipc_socket_bind(int fd,
                               const unsigned char *path_bytes,
                               int path_len) {
  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  if (path_len >= (int)sizeof(addr.sun_path)) return -1;
  memcpy(addr.sun_path, path_bytes, path_len);
  addr.sun_path[path_len] = '\0';
  unlink(addr.sun_path);
  if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) return -1;
  return 0;
}

int subprocess_ipc_socket_listen(int fd, int backlog) {
  if (listen(fd, backlog) < 0) return -1;
  return 0;
}

int subprocess_ipc_socket_accept(int fd) {
  struct sockaddr_un client_addr;
  socklen_t client_len = sizeof(client_addr);
  int client_fd = accept(fd, (struct sockaddr *)&client_addr, &client_len);
  if (client_fd < 0) return -1;
  return client_fd;
}

int subprocess_ipc_socket_connect(const unsigned char *path_bytes,
                                  int path_len) {
  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  if (path_len >= (int)sizeof(addr.sun_path)) return -1;
  memcpy(addr.sun_path, path_bytes, path_len);
  addr.sun_path[path_len] = '\0';

  int fd = socket(AF_UNIX, SOCK_STREAM, 0);
  if (fd < 0) return -1;

  if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    close(fd);
    return -1;
  }
  return fd;
}

void subprocess_ipc_socket_close(int fd) {
  if (fd >= 0) close(fd);
}

int subprocess_ipc_socket_unlink(const unsigned char *path_bytes,
                                 int path_len) {
  char path_buf[108];
  if (path_len >= (int)sizeof(path_buf)) return -1;
  memcpy(path_buf, path_bytes, path_len);
  path_buf[path_len] = '\0';
  return unlink(path_buf);
}

// ---------- I/O ----------

int subprocess_ipc_read(int fd, unsigned char *buf, int max_len) {
  ssize_t n = read(fd, buf, max_len);
  if (n < 0) return -1;
  return (int)n;
}

int subprocess_ipc_write(int fd, const unsigned char *buf, int len) {
  int total = 0;
  while (total < len) {
    ssize_t n = write(fd, buf + total, len - total);
    if (n < 0) {
      if (errno == EINTR) continue;
      return -1;
    }
    total += (int)n;
  }
  return total;
}

int subprocess_ipc_read_exact(int fd, unsigned char *buf, int len) {
  int total = 0;
  while (total < len) {
    ssize_t n = read(fd, buf + total, len - total);
    if (n <= 0) {
      if (n < 0 && errno == EINTR) continue;
      return -1;
    }
    total += (int)n;
  }
  return 0;
}

// ---------- Non-blocking / polling ----------

int subprocess_ipc_set_nonblocking(int fd) {
  int flags = fcntl(fd, F_GETFL, 0);
  if (flags < 0) return -1;
  if (fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) return -1;
  return 0;
}

int subprocess_ipc_poll_read(int fd, int timeout_ms) {
  struct pollfd pfd;
  pfd.fd = fd;
  pfd.events = POLLIN;
  pfd.revents = 0;
  int ret = poll(&pfd, 1, timeout_ms);
  if (ret < 0) return -1;
  if (ret == 0) return 0;
  if (pfd.revents & (POLLIN | POLLHUP)) return 1;
  return -1;
}

// ---------- Utility ----------

int subprocess_ipc_get_peer_pid(int fd) {
#ifdef __APPLE__
  pid_t pid;
  socklen_t pid_len = sizeof(pid);
  if (getsockopt(fd, SOL_LOCAL, LOCAL_PEERPID, &pid, &pid_len) == 0) {
    return (int)pid;
  }
  return -1;
#elif defined(__linux__)
  struct ucred cred;
  socklen_t len = sizeof(cred);
  if (getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &cred, &len) == 0) {
    return (int)cred.pid;
  }
  return -1;
#else
  (void)fd;
  return -1;
#endif
}

#endif // !_WIN32
