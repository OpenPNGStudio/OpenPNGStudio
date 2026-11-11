#include <windows.h>
#include <dwmapi.h>

#pragma comment(lib, "dwmapi.lib")

#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

BOOL IsSystemDarkModeEnabled(void)
{
    HKEY hKey;
    DWORD data = 1;
    DWORD dataSize = sizeof(data);

    LSTATUS status = RegOpenKeyExA(
        HKEY_CURRENT_USER,
        "Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize",
        0, KEY_READ, &hKey
    );

    if (status == ERROR_SUCCESS) {
        RegQueryValueExA(hKey, "AppsUseLightTheme", NULL, NULL, (LPBYTE)&data, &dataSize);
        RegCloseKey(hKey);
    }

    return data == 0;
}

void UpdateTitleBarTheme()
{
    BOOL useDarkMode = IsSystemDarkModeEnabled();
    DwmSetWindowAttribute(
        GetWindowHandle(),
        DWMWA_USE_IMMERSIVE_DARK_MODE,
        &useDarkMode,
        sizeof(useDarkMode)
    );
}