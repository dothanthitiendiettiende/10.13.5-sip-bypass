#import <Foundation/Foundation.h>

#include <assert.h>
#include <sandbox.h>
#include <spawn.h>
#include <stdio.h>
#include <unistd.h>

#include "log.h"

int sandbox_init_with_parameters(const char *profile, uint64_t flags,
                                 const char *const parameters[],
                                 char **errorbuf);

extern char **environ;

const char *relative(const char *component) {
    NSString *base = [[NSBundle mainBundle] bundlePath];
    if (!component)
        return [base UTF8String];
    NSString *tail = [NSString stringWithUTF8String:component];
    return [[base stringByAppendingPathComponent:tail] UTF8String];
}

int main(int argc, char *argv[]) {
    const char profile[] =
        "(version 1)"
        "(allow default)"
        "(deny file-read*"
        "    (literal "
        "\"/System/Library/PrivateFrameworks/Swift/libswiftDemangle.dylib\")"
        "    (literal "
        "\"/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/"
        "libswiftDemangle.dylib\")"
        ")";

    const char *null_params[] = {NULL};
    int result = sandbox_init_with_parameters(profile, 0, null_params, NULL);
    assert(result == 0);

    pid_t pid_swift;
    const char *taytay = relative("taytay");
    assert(posix_spawn(&pid_swift, taytay, NULL, NULL,
                       (char *const *)null_params, environ) == 0);

    char pid_str[16];
    snprintf(pid_str, sizeof pid_str, "%d", pid_swift);
    LOG("taytay pid: %d\n", pid_swift);

    const char *target_binary = relative("symbols");
    char *target_argv[] = {(char *)target_binary, pid_str, "-printDemangling",
                           NULL};

    setenv("DEVELOPER_DIR", relative(NULL), 1);

    pid_t pid_sym;
    int status;
    posix_spawn_file_actions_t action;
    posix_spawn_file_actions_init(&action);
    posix_spawn_file_actions_addopen(&action, STDOUT_FILENO, "/dev/null",
                                     O_RDONLY, 0);

    status = posix_spawn(&pid_sym, target_binary, &action, NULL,
                         (char *const *)target_argv, environ);
    assert(status == 0);
    waitpid(pid_sym, &status, 0);
    kill(pid_swift, SIGKILL);
}