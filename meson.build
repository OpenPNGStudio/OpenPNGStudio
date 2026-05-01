project(
    'OpenPNGStudio',
    'c', 'cpp',
    license: ['GPL-3.0-or-later', 'CC-BY-NC-SA-4.0'],
    license_files: [
        'COPYING',
        'assets/Oxy/LICENSE.txt',
        'assets/Oxy/CREDIT.txt',
    ],
    version: '0.3.0',
    meson_version: '>= 1.2.0',
    default_options: ['c_std=c17']
)

# Modules
cmake = import('cmake')
fs = import('fs')

# Programs
cc = meson.get_compiler('c')
curl = find_program('curl')
c3c = find_program('c3c')
ascli = find_program('appstreamcli', required: false)
nasm = find_program('nasm', required: false)

# Dependencies
raylib_o = cmake.subproject_options()
raylib_o.add_cmake_defines({
    'BUILD_EXAMPLES': false,
    'CUSTOMIZE_BUILD': true,
    'SUPPORT_MODULE_RMODELS': false,
    'SUPPORT_MODULE_RAUDIO': false,
    'SUPPORT_GESTURE_SYSTEM': false,
    'SUPPORT_RPRAND_GENERATOR': false,
    'SUPPORT_MOUSE_GESTURES': false,
    'SUPPORT_SSH_KEYBOARD_RPI': false,
    'SUPPORT_FILEFORMAT_BMP': true,
    'SUPPORT_FILEFORMAT_JPG': true,
    'SUPPORT_FILEFORMAT_PNG': true,
    'SUPPORT_FILEFORMAT_TGA': true,
    'SUPPORT_FILEFORMAT_GIF': true,
    'SUPPORT_FILEFORMAT_QOI': true,
    'SUPPORT_FILEFORMAT_PSD': true,
    'SUPPORT_FILEFORMAT_DDS': true,
    'SUPPORT_GIF_RECORDING': false,
    'SUPPORT_SCREEN_CAPTURE': false,
    'CMAKE_SKIP_INSTALL_RULES': true,
})

libavif_o = cmake.subproject_options()
libavif_o.add_cmake_defines({
    'AVIF_CODEC_AOM': 'LOCAL',
    'AVIF_CODEC_DAV1D': false,
    'AVIF_CODEC_LIBGAV1': false,
    'AVIF_CODEC_RAV1E': false,
    'AVIF_CODEC_SVT': false,
    'AVIF_LIBYUV': 'LOCAL',
    'BUILD_SHARED_LIBS': false,
})

if not nasm.found()
    libavif_o.add_cmake_defines({
        'AOM_TARGET_CPU': 'generic'
    })
endif

libjxl_o = cmake.subproject_options()
libjxl_o.add_cmake_defines({
    'JPEGXL_ENABLE_FUZZERS': false,
    'JPEGXL_ENABLE_TOOLS': false,
    'JPEGXL_ENABLE_JPEGLI': false,
    'JPEGXL_ENABLE_JPEGLI_LIBJPEG': false,
    'JPEGXL_ENABLE_SJPEG': false,
    'JPEGXL_ENABLE_OPENEXR': false,
    'JPEGXL_ENABLE_SKCMS': true,
    'JPEGXL_ENABLE_TRANSCODE_JPEG': false,
    'JPEGXL_ENABLE_BOXES': false,
    'JPEGXL_ENABLE_DOXYGEN': false,
    'JPEGXL_ENABLE_MANPAGES': false,
    'JPEGXL_ENABLE_BENCHMARK': false,
    'JPEGXL_ENABLE_EXAMPLES': false,
    'JPEGXL_ENABLE_JNI': false,
    'BROTLI_BUILD_TOOLS': false,
    'BUILD_SHARED_LIBS': false,
})

raylib_p = cmake.subproject('raylib', options: raylib_o)
sqlite_p = subproject('sqlite3', default_options: ['default_library=static'])
libavif_p = cmake.subproject('libavif', options: libavif_o)
libjxl_p = cmake.subproject('libjxl', options: libjxl_o)
libwebp_p = subproject('libwebp', default_options: ['default_library=static'])

raylib = raylib_p.dependency('raylib')
sqlite = sqlite_p.get_variable('sqlite3_dep')
libavif = [
    libavif_p.dependency('avif'),
    libavif_p.dependency('aom'),
    libavif_p.dependency('yuv')
]
libjxl = [
    libjxl_p.dependency('jxl'),
    libjxl_p.dependency('jxl_threads')
]
libwebp = [
    libwebp_p.get_variable('webp_dep'),
    libwebp_p.get_variable('webpdecoder_dep'),
    libwebp_p.get_variable('webpdemux_dep'),
]

# Headers
vendor_headers = [
    'https://raw.githubusercontent.com/OpenPNGStudio/Nuklear/refs/heads/master/nuklear.h',
    'https://raw.githubusercontent.com/OpenPNGStudio/raylib-nuklear/refs/heads/master/include/raylib-nuklear.h',
    'https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h',
    'https://raw.githubusercontent.com/raysan5/raygui/refs/heads/master/src/raygui.h',
    'https://raw.githubusercontent.com/nothings/stb/refs/heads/master/stb_image.h',
]

foreach url : vendor_headers
    file = 'include/vendor/' + fs.name(url)
    if not fs.exists(file)
        message('Downloading ' + file)
        run_command(curl, '-L', '-o', file, url, check: true)
    else
        message('File ' + file + ' exists')
    endif
endforeach

# C3
c3_version = c3c.version()
c3_hash = 'unknown'

c3_target_version = '0.7.11'
c3_target_hash = '71c5d5bafd700d7d2f2a0fe282fc93a7420faf9e'

output = run_command(c3c, '--version', check: true).stdout()

foreach line : output.splitlines()
    if line.to_lower().contains('hash')
        c3_hash = line.split(':')[1].strip()
    endif
endforeach

assert(c3_version == c3_target_version)
assert(
    c3_hash == c3_target_hash,
    'C3 compiler hash does not match: ' + c3_target_hash + ' != ' + c3_hash,
)

# OpenPNGStudio and opng
subdir('src')
executable(
    'OpenPNGStudio',
    c_src,
    dependencies: [raylib, sqlite, app_dep, libavif, libjxl, libwebp, extra_libs],
    include_directories: ['include', 'include/vendor'],
    install: true,
    install_dir: 'bin',
    win_subsystem: 'console',
)
subdir('src/opng')

executable(
    'opng',
    opng_c_srcs,
    dependencies: [sqlite, opng_dep, libavif, libjxl, libwebp, extra_libs],
    include_directories: ['include'],
    install: true,
    install_dir: 'bin',
    win_subsystem: 'console',
    c_args: ['-DOPNG_STANDALONE'],
    cpp_args: ['-DOPNG_STANDALONE']
)

# Install
subdir('assets')
subdir('licenses')
subdir('data')

# Note: when installing use --skip-subprojects
