# libuv
set(BUILD_SHARED_LIBS OFF)
set(LIBUV_BUILD_TESTS OFF)
set(LIBUV_BUILD_BENCH OFF)
set(LIBUV_BUILD_SHARED OFF)

FetchContent_Declare(
    libuv 
    URL "https://github.com/libuv/libuv/archive/refs/tags/v${LIBUV_VERSION}.tar.gz"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

FetchContent_MakeAvailable(libuv)

# raylib
set(BUILD_EXAMPLES OFF)
set(CUSTOMIZE_BUILD ON)
set(SUPPORT_MODULE_RMODELS OFF)
set(SUPPORT_MODULE_RAUDIO OFF)
set(SUPPORT_GESTURE_SYSTEM OFF)
set(SUPPORT_RPRAND_GENERATOR OFF)
set(SUPPORT_MOUSE_GESTURES OFF)
set(SUPPORT_SSH_KEYBOARD_RPI OFF)
set(SUPPORT_GIF_RECORDING OFF)
set(SUPPORT_FILEFORMAT_BMP ON)
set(SUPPORT_FILEFORMAT_JPG ON)
set(SUPPORT_FILEFORMAT_PNG ON)
set(SUPPORT_FILEFORMAT_TGA ON)
set(SUPPORT_FILEFORMAT_GIF ON)
set(SUPPORT_FILEFORMAT_QOI ON)
set(SUPPORT_FILEFORMAT_PSD ON)
set(SUPPORT_FILEFORMAT_DDS ON)

FetchContent_Declare(
    raylib
    URL "https://github.com/OpenPNGStudio/raylib/archive/refs/heads/master.tar.gz"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

FetchContent_MakeAvailable(raylib)

# libunuv
FetchContent_Declare(
    libunuv
    URL "https://github.com/LowByteFox/libunuv/archive/refs/heads/main.tar.gz"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

FetchContent_MakeAvailable(libunuv)

if (WIN32)
    # mman
    FetchContent_Declare(
        mman
        URL "https://github.com/boldowa/mman-win32/archive/refs/heads/master.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    FetchContent_MakeAvailable(mman)
endif()
