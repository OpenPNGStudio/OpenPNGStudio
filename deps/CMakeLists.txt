if (WIN32)
else()
# zstd
set(ZSTD_BUILD_STATIC ON)
set(ZSTD_BUILD_SHARED OFF)
set(ZSTD_BUILD_PROGRAMS OFF)

FetchContent_Declare(
    zstd
    URL "https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    SOURCE_SUBDIR build/cmake
)

FetchContent_MakeAvailable(zstd)

# libarchive
set(ENABLE_OPENSSL OFF)
set(ENABLE_LIBB2 OFF)
set(ENABLE_LZ4 OFF)
set(ENABLE_LZMA OFF)
set(ENABLE_ZLIB OFF)
set(ENABLE_BZip2 OFF)
set(ENABLE_LIBXML2 OFF)
set(ENABLE_EXPAT OFF)
set(ENABLE_WIN32_XMLLITE OFF)
set(ENABLE_PCREPOSIX OFF)
set(ENABLE_PCRE2POSIX OFF)
set(ENABLE_CNG OFF)
set(ENABLE_CPIO OFF)
set(ENABLE_CAT OFF)
set(ENABLE_UNZIP OFF)
set(ENABLE_ICONV OFF)
set(ENABLE_TEST OFF)
set(BUILD_SHARED_LIBS OFF)

FetchContent_Declare(
    libarchive 
    URL "https://github.com/libarchive/libarchive/releases/download/v${LIBARCHIVE_VERSION}/libarchive-${LIBARCHIVE_VERSION}.tar.gz"
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
)

FetchContent_MakeAvailable(libarchive)

endif()

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
set(SUPPORT_FILEFORMAT_BMP ON)
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
    # dirent
    FetchContent_Declare(
        dirent
        URL "https://github.com/tronkko/dirent/archive/refs/heads/master.tar.gz"
        DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    )

    FetchContent_MakeAvailable(dirent)
endif()