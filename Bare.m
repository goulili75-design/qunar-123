// Bare minimum C only - no Foundation, no ObjC
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

__attribute__((constructor))
static void bare_init() {
    int fd = open("/tmp/BARE_C_LOADED", O_CREAT|O_WRONLY, 0644);
    if (fd >= 0) {
        write(fd, "ok", 2);
        close(fd);
    }
}
