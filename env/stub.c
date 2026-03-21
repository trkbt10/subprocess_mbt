/*
 * subprocess/env - Platform environment detection and temp directory resolution
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#define OS_NAME "Windows"
#include <windows.h>
#elif defined(__APPLE__)
#define OS_NAME "Darwin"
#elif defined(__linux__)
#define OS_NAME "Linux"
#else
#define OS_NAME "Unknown"
#endif

/*
 * Get OS name into buffer.
 * Returns: bytes written (excluding null), or -1 on error.
 */
int subprocess_env_get_os_name(char* buffer, int buffer_len) {
    if (!buffer || buffer_len <= 0) return -1;
    const char* os_name = OS_NAME;
    int len = (int)strlen(os_name);
    if (len >= buffer_len) return -1;
    memcpy(buffer, os_name, len);
    return len;
}


/*
 * Get temp directory path into buffer.
 * Returns: bytes written (excluding null), or -1 on error.
 */
int subprocess_env_get_temp_dir(char* buffer, int buffer_len) {
    if (!buffer || buffer_len <= 0) return -1;
#ifdef _WIN32
    DWORD len = GetTempPathA(buffer_len, buffer);
    if (len == 0 || (int)len >= buffer_len) return -1;
    /* Remove trailing backslash if present */
    if (len > 1 && buffer[len - 1] == '\\') {
        buffer[len - 1] = '\0';
        len--;
    }
    return (int)len;
#else
    const char* tmpdir = getenv("TMPDIR");
    if (!tmpdir || tmpdir[0] == '\0') tmpdir = "/tmp";
    int len = (int)strlen(tmpdir);
    /* Remove trailing slash if present */
    while (len > 1 && tmpdir[len - 1] == '/') len--;
    if (len >= buffer_len) return -1;
    memcpy(buffer, tmpdir, len);
    return len;
#endif
}
