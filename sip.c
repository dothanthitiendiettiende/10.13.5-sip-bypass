#include <string.h>
#include <stdio.h>
#include <assert.h>

#include "log.h"

__attribute__((constructor)) void run() {
    LOG("ready");
    assert(geteuid() == 0);

    const char *content = "hello";
    FILE* fp = fopen("/System/Library/sip.txt", "w");
    assert(fp);
    fputs(content, fp);
    fclose(fp);
    LOG("done");
}
