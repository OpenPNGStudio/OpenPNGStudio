#include <limits.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <dlfcn.h>

char *freebsd_executable_path_raw()
{
    char buffer1[PATH_MAX];
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PATHNAME, -1 };
    size_t size = PATH_MAX;

    if (sysctl(mib, (u_int) (sizeof(mib) / sizeof(mib[0])), buffer1, &size, NULL, 0) != 0)
	    return NULL;

    return realpath(buffer1, NULL);
}
