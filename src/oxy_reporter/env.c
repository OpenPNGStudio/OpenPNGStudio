#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <raylib.h>
#include <GLFW/glfw3.h>

#if defined(_WIN32)
#include <windows.h>
#else
#include <sys/utsname.h>
#if defined(__FreeBSD__)
#include <sys/types.h>
#include <sys/sysctl.h>
#endif
#endif

typedef struct {
    char os[128];
    char cpu[128];
    char gpu[256];
    char display[32];
} Env;

void gather_env(Env *env)
{
#if defined(_WIN32)
#if defined(_M_X64)
    snprintf(env->os, sizeof(env->os), "Windows (x86_64)");
#elif defined(_M_ARM64)
    snprintf(env->os, sizeof(env->os), "Windows (aarch64)");
#else
    snprintf(env->os, sizeof(env->os), "Windows (x86)");
#endif
#else
    struct utsname u;
    if (uname(&u) == 0) {
        snprintf(env->os, sizeof(env->os), "%s %s (%s)", u.sysname, u.release, u.machine);
    } else {
        snprintf(env->os, sizeof(env->os), "Unknown Unix");
    }
#endif

#if defined(__FreeBSD__)
    size_t len = sizeof(env->cpu);
    if (sysctlbyname("hw.model", env->cpu, &len, NULL, 0) != 0)
        snprintf(env->cpu, sizeof(env->cpu), "Unknown BSD CPU");
#elif defined(__linux__)
    FILE *f = fopen("/proc/cpuinfo", "r");
    if (f) {
        char line[256];
        while (fgets(line, sizeof(line), f)) {
            if (strncmp(line, "model name", 10) == 0) {
                char *colon = strchr(line, ':');
                if (colon) {
                    colon++;
                    while (*colon == ' ' || *colon == '\t') colon++;
                    size_t l = strlen(colon);
                    if (l > 0 && colon[l - 1] == '\n') colon[l - 1] = '\0';
                    snprintf(env->cpu, sizeof(env->cpu), "%s", colon);
                    break;
                }
            }
        }
        fclose(f);
    }
    if (env->cpu[0] == '\0') snprintf(env->cpu, sizeof(env->cpu), "Generic Linux CPU");
#elif defined(_WIN32)
    HKEY hKey;
    if (RegOpenKeyExA(HKEY_LOCAL_MACHINE, 
        "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0", 
        0, KEY_READ, &hKey) == ERROR_SUCCESS)
    {
        DWORD size = sizeof(env->cpu);
        RegQueryValueExA(hKey, "ProcessorNameString", NULL, NULL, (LPBYTE) env->cpu, &size);
        RegCloseKey(hKey);
    }
    if (env->cpu[0] == '\0') snprintf(env->cpu, sizeof(env->cpu), "Generic Windows CPU");
#endif

#if defined(_WIN32)
    snprintf(env->display, sizeof(env->display), "Windows DWM");
#else
    if (getenv("WAYLAND_DISPLAY"))
        snprintf(env->display, sizeof(env->display), "Wayland (%s)", getenv("WAYLAND_DISPLAY"));
    else if (getenv("DISPLAY"))
        snprintf(env->display, sizeof(env->display), "X11 (%s)", getenv("DISPLAY"));
    else
        snprintf(env->display, sizeof(env->display), "None ???");
#endif

    const char *renderer = (const char*) glGetString(0x1F01); /* GL_RENDERER */
    const char *version = (const char*) glGetString(0x1F02); /* GL_VERSION */

    snprintf(env->gpu, sizeof(env->gpu), "%s [%s]", 
        renderer ? renderer : "Unknown GPU", version ? version : "Unknown GL");
}
