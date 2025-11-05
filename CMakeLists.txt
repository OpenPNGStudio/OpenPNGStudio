cmake_minimum_required(VERSION 3.22)
project(OpenPNGStudio VERSION 0.3.0)

set(CMAKE_C_STANDARD 17)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(FETCHCONTENT_QUIET NO)

set(ZSTD_VERSION 1.5.7 CACHE STRING "Zstandard version used")
set(LIBARCHIVE_VERSION 3.8.2 CACHE STRING "Libarchive version used")
set(LIBUV_VERSION 1.51.0 CACHE STRING "Libuv version used")

include(FetchContent)

add_subdirectory(deps)

set(VENDOR_INCLUDE_DIR ${CMAKE_SOURCE_DIR}/include/vendor)
set(VENDOR_SRC_DIR ${CMAKE_SOURCE_DIR}/src/vendor)
file(MAKE_DIRECTORY ${VENDOR_INCLUDE_DIR})
file(MAKE_DIRECTORY ${VENDOR_SRC_DIR})

function(fetch_file url dest_dir)
    get_filename_component(filename ${url} NAME)
    set(dest "${dest_dir}/${filename}")

    if(NOT EXISTS ${dest})
        message(STATUS "Fetching ${filename} from ${url}")
        file(DOWNLOAD ${url} ${dest} SHOW_PROGRESS EXPECTED_HASH ANY)
    else()
        message(STATUS "Already fetched: ${filename}")
    endif()
endfunction()

set(VENDOR_HEADERS
    "https://raw.githubusercontent.com/OpenPNGStudio/Nuklear/refs/heads/master/nuklear.h"
    "https://raw.githubusercontent.com/OpenPNGStudio/raylib-nuklear/refs/heads/master/include/raylib-nuklear.h"
    "https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h"
    "https://raw.githubusercontent.com/cktan/tomlc99/refs/heads/master/toml.h"
    "https://raw.githubusercontent.com/raysan5/raygui/refs/heads/master/src/raygui.h"
)

set(VENDOR_SOURCES
    "https://raw.githubusercontent.com/cktan/tomlc99/refs/heads/master/toml.c"
)

foreach(url IN LISTS VENDOR_HEADERS)
    fetch_file(${url} ${VENDOR_INCLUDE_DIR})
endforeach()

foreach(url IN LISTS VENDOR_SOURCES)
    fetch_file(${url} ${VENDOR_SRC_DIR})
endforeach()

file(GLOB_RECURSE SRCS src/*.c)

add_library(${PROJECT_NAME} STATIC ${SRCS})
target_include_directories(${PROJECT_NAME} PUBLIC
    "${libuv_SOURCE_DIR}/include"
    "${zstd_SOURCE_DIR}/lib"
    "${libarchive_SOURCE_DIR}/libarchive"
    "${raylib_SOURCE_DIR}"
    "${libunuv_SOURCE_DIR}/include")
target_include_directories(${PROJECT_NAME} PUBLIC include include/vendor)

install(TARGETS ${PROJECT_NAME})
