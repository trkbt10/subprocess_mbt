// Windows AF_UNIX implementation (Winsock2, Windows 10 Build 17063+)

#ifdef _WIN32

#include "ipc.h"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif

#include <winsock2.h>
#include <afunix.h>
#include <ws2tcpip.h>
#include <windows.h>
#include <string.h>

#pragma comment(lib, "Ws2_32.lib")

// Auto-initialize Winsock on first use.
static int g_wsa_initialized = 0;
static void ensure_wsa_init(void) {
  if (!g_wsa_initialized) {
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) == 0) {
      g_wsa_initialized = 1;
    }
  }
}

// ---------- Socket lifecycle ----------

int subprocess_ipc_socket_create(void) {
  ensure_wsa_init();
  SOCKET s = socket(AF_UNIX, SOCK_STREAM, 0);
  if (s == INVALID_SOCKET) return -1;
  return (int)s;
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

  DeleteFileA(addr.sun_path);

  if (bind((SOCKET)fd, (struct sockaddr *)&addr, sizeof(addr)) == SOCKET_ERROR)
    return -1;
  return 0;
}

int subprocess_ipc_socket_listen(int fd, int backlog) {
  if (listen((SOCKET)fd, backlog) == SOCKET_ERROR) return -1;
  return 0;
}

int subprocess_ipc_socket_accept(int fd) {
  struct sockaddr_un client_addr;
  int client_len = sizeof(client_addr);
  SOCKET client = accept((SOCKET)fd, (struct sockaddr *)&client_addr,
                          &client_len);
  if (client == INVALID_SOCKET) return -1;
  return (int)client;
}

int subprocess_ipc_socket_connect(const unsigned char *path_bytes,
                                  int path_len) {
  ensure_wsa_init();
  struct sockaddr_un addr;
  memset(&addr, 0, sizeof(addr));
  addr.sun_family = AF_UNIX;
  if (path_len >= (int)sizeof(addr.sun_path)) return -1;
  memcpy(addr.sun_path, path_bytes, path_len);
  addr.sun_path[path_len] = '\0';

  SOCKET s = socket(AF_UNIX, SOCK_STREAM, 0);
  if (s == INVALID_SOCKET) return -1;

  if (connect(s, (struct sockaddr *)&addr, sizeof(addr)) == SOCKET_ERROR) {
    closesocket(s);
    return -1;
  }
  return (int)s;
}

void subprocess_ipc_socket_close(int fd) {
  if (fd >= 0) closesocket((SOCKET)fd);
}

int subprocess_ipc_socket_unlink(const unsigned char *path_bytes,
                                 int path_len) {
  char path_buf[108];
  if (path_len >= (int)sizeof(path_buf)) return -1;
  memcpy(path_buf, path_bytes, path_len);
  path_buf[path_len] = '\0';
  return DeleteFileA(path_buf) ? 0 : -1;
}

// ---------- I/O ----------

int subprocess_ipc_read(int fd, unsigned char *buf, int max_len) {
  int n = recv((SOCKET)fd, (char *)buf, max_len, 0);
  if (n == SOCKET_ERROR) return -1;
  return n;
}

int subprocess_ipc_write(int fd, const unsigned char *buf, int len) {
  int total = 0;
  while (total < len) {
    int n = send((SOCKET)fd, (const char *)(buf + total), len - total, 0);
    if (n == SOCKET_ERROR) return -1;
    total += n;
  }
  return total;
}

int subprocess_ipc_read_exact(int fd, unsigned char *buf, int len) {
  int total = 0;
  while (total < len) {
    int n = recv((SOCKET)fd, (char *)(buf + total), len - total, 0);
    if (n <= 0) return -1;
    total += n;
  }
  return 0;
}

// ---------- Non-blocking / polling ----------

int subprocess_ipc_set_nonblocking(int fd) {
  u_long mode = 1;
  if (ioctlsocket((SOCKET)fd, FIONBIO, &mode) == SOCKET_ERROR) return -1;
  return 0;
}

int subprocess_ipc_poll_read(int fd, int timeout_ms) {
  WSAPOLLFD pfd;
  pfd.fd = (SOCKET)fd;
  pfd.events = POLLIN;
  pfd.revents = 0;
  int ret = WSAPoll(&pfd, 1, timeout_ms);
  if (ret == SOCKET_ERROR) return -1;
  if (ret == 0) return 0;
  if (pfd.revents & (POLLIN | POLLHUP)) return 1;
  return -1;
}

// ---------- Utility ----------

int subprocess_ipc_get_peer_pid(int fd) {
  // Windows does not expose peer PID for AF_UNIX sockets.
  (void)fd;
  return -1;
}

#endif // _WIN32
