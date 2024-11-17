#include <stdio.h>
#include <str.h>

size_t sized_strncpy(char *dest, const char *src, size_t n)
{
    size_t count = 0;

    for (; n > 0 && (*dest = *src); dest++, src++, count++, n--);

    return count;
}

#ifdef _WIN32
char *strchrnul(const char *p, int ch)
{
	char c;

	c = ch;
	for (;; ++p) {
		if (*p == c || *p == '\0')
			return ((char *)p);
	}
}
#endif
