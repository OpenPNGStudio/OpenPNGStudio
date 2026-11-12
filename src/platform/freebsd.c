#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <limits.h>

#include <unistd.h>
#include <glob.h>
#include <dlfcn.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/event.h>
#include <sys/wait.h>
#include <sys/stat.h>

struct freebsd_settings {
    bool enabled;
    int compression;
    char format[512];
};

static bool get_settings(struct freebsd_settings *settings);
static const char *resolve_fmt(const char *format, pid_t ppid, int signal);

char *freebsd_executable_path_raw()
{
    char buffer1[PATH_MAX];
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };
    size_t size = PATH_MAX;

    if (sysctl(mib, (u_int) (sizeof(mib) / sizeof(mib[0])), buffer1, &size, NULL, 0) != 0)
	    return NULL;

    return realpath(buffer1, NULL);
}

void freebsd_crash_handling(const char *reporter)
{
    struct freebsd_settings cfg;

    if (!get_settings(&cfg))
        return;

    if (!cfg.enabled)
        return;

    pid_t ppid = getpid();

    switch (fork()) {
    case 0:
        break;
    case -1:
    default:
        return;
    }

    int kq = kqueue();
    if (kq < 0)
        exit(1);

    struct kevent ke;
    EV_SET(&ke, ppid, EVFILT_PROC, EV_ADD | EV_ENABLE, NOTE_EXIT, 0, NULL);

    if (kevent(kq, &ke, 1, NULL, 0, NULL) < 0)
        exit(1);

    struct kevent event;
    int nev = kevent(kq, NULL, 0, &event, 1, NULL);

    char found_file[PATH_MAX] = {0};
    char resolved_core[PATH_MAX] = {0};
    const char *corefile = "NO CORE";

    if (nev <= 0 || !WIFSIGNALED(event.data) || !WCOREDUMP(event.data)) {
        close(kq);
        exit(0);
    }

    int sig = WTERMSIG(event.data);
    const char *base_pattern = resolve_fmt(cfg.format, ppid, sig);

    char pattern[PATH_MAX];
    snprintf(pattern, sizeof(pattern), "%s*", base_pattern);

    glob_t g;
    if (glob(pattern, GLOB_NOSORT, NULL, &g) == 0) {
        time_t latest_mtime = 0;

        for (size_t i = 0; i < g.gl_pathc; i++) {
            struct stat st;
            if (stat(g.gl_pathv[i], &st) == 0 && st.st_mtime > latest_mtime) {
                latest_mtime = st.st_mtime;
                strncpy(found_file, g.gl_pathv[i], sizeof(found_file) - 1);
            }
        }
        globfree(&g);

        if (found_file[0] != '\0') {
            if (realpath(found_file, resolved_core) != NULL) {
                corefile = resolved_core;
            } else {
                /* just in case */
                corefile = found_file;
            }
        }
    }

    close(kq);

    execl(reporter, reporter, corefile, NULL);
    exit(0);
}

static bool get_settings(struct freebsd_settings *settings)
{
    int val = 0;
    size_t len = sizeof(int);

    if (sysctlbyname("kern.coredump", &val, &len, NULL, 0) != 0)
        return false;

    settings->enabled = val != 0;

    if (sysctlbyname("kern.compress_user_cores", &val, &len, NULL, 0) != 0)
        settings->compression = 0;
    else
        settings->compression = val;

    len = sizeof(settings->format);
    if (sysctlbyname("kern.corefile", settings->format, &len, NULL, 0) != 0)
        return false;

    return true;
}

static char resolved[1024];

static const char *resolve_fmt(const char *format, pid_t ppid, int signal)
{
    size_t i = 0;

    while (*format && i < sizeof(resolved) - 1) {
        if (*format == '%') {
            format++;
            if (!*format)
                break;

            char buf[64];
            int len = 0;

            switch (*format) {
            case 'H':
                gethostname(buf, sizeof(buf));
                len = strnlen(buf, sizeof(buf));
                break;
            case 'I':
                buf[0] = '*';
                len = 1;
                break;
            case 'N':
                len = snprintf(buf, sizeof(buf), "OpenPNGStudio");
                break;
            case 'P':
                len = snprintf(buf, sizeof(buf), "%d", (int)ppid);
                break;
            case 'S':
                len = snprintf(buf, sizeof(buf), "%d", signal);
                break;
            case 'U':
                len = snprintf(buf, sizeof(buf), "%u", (unsigned int)getuid());
                break;
            case '%':
                buf[0] = '%';
                len = 1;
                break;
            default:
                buf[0] = '*';
                len = 1;
                break;
            }

            if (len > 0 && i + (size_t)len < sizeof(resolved) - 1) {
                memcpy(resolved + i, buf, len);
                i += (size_t)len;
            }
            format++;
        } else {
            resolved[i++] = *format++;
        }
    }

    resolved[i] = '\0';
    return resolved;
}
