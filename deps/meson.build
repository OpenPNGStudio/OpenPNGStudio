# Options
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
    'SUPPORT_FILEFORMAT_PSD': false,
    'SUPPORT_FILEFORMAT_DDS': true,
    'SUPPORT_GIF_RECORDING': false,
    'SUPPORT_SCREEN_CAPTURE': false,
    'CMAKE_SKIP_INSTALL_RULES': true,
})

if host_machine.system() == 'linux'
    raylib_o.add_cmake_defines({
        'GLFW_BUILD_X11': true,
        'GLFW_BUILD_WAYLAND': true,
    })
endif

libaom_o = cmake.subproject_options()
libaom_o.add_cmake_defines({
    'CONFIG_WEBM_IO': false,
    'ENABLE_APPS': false,
    'ENABLE_DOCS': false,
    'ENABLE_EXAMPLES': false,
    'ENABLE_TESTS': false,
    'ENABLE_TESTDATA': false,
    'ENABLE_TOOLS': false,
    'CONFIG_PIC': true,
    'CONFIG_LIBYUV': false,
    'BUILD_SHARED_LIBS': false
})

libyuv_o = cmake.subproject_options()
libyuv_o.add_cmake_defines({
    'BUILD_SHARED_LIBS': false
})

libaom_inc = here / 'subprojects/libaom'
libyuv_inc = here / 'subprojects/libyuv/include'

libavif_o = cmake.subproject_options()
libavif_o.add_cmake_defines({
    'AVIF_CODEC_AOM': 'SYSTEM',
    'AVIF_CODEC_DAV1D': false,
    'AVIF_CODEC_LIBGAV1': false,
    'AVIF_CODEC_RAV1E': false,
    'AVIF_CODEC_SVT': false,
    'AVIF_LIBYUV': 'SYSTEM',
    'BUILD_SHARED_LIBS': false,
    'AOM_LIBRARY': 'libaom.a',
    'AOM_INCLUDE_DIR': libaom_inc,
    'LIBYUV_LIBRARY': 'libyuv.a',
    'LIBYUV_INCLUDE_DIR': libyuv_inc,
})

libavif_o.append_compile_args('c', '-I' + libaom_inc)
libavif_o.append_compile_args('c', '-I' + libyuv_inc)

if not nasm.found()
    libavif_o.add_cmake_defines({
        'AOM_TARGET_CPU': 'generic'
    })
else
    libaom_o.add_cmake_defines({
        'ENABLE_NASM': true
    })
endif

if get_option('jxl')
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
        'PROVISION_DEPENDENCIES': true,
        'BUILD_SHARED_LIBS': false,
    })
endif

# Projects
raylib_p = cmake.subproject('raylib', options: raylib_o)

sqlite_p = subproject('sqlite3', default_options: {
    'default_library': 'static'
})

libyuv_p = cmake.subproject('libyuv', options: libyuv_o)
libaom_p = cmake.subproject('libaom', options: libaom_o)
libavif_p = cmake.subproject('libavif', options: libavif_o)

libwebp_p = subproject('libwebp', default_options: {
    'default_library': 'static'
})

if get_option('jxl')
    libjxl_p = cmake.subproject('libjxl', options: libjxl_o)
endif

# Includes
includes += raylib_p.get_variable('raylib_inc')

# Deps
deps += raylib_p.dependency('raylib')

deps += sqlite_p.get_variable('sqlite3_dep')

deps += [
    libyuv_p.dependency('yuv'),
    libaom_p.dependency('aom'),
    libavif_p.dependency('avif')
]

deps += [
    libwebp_p.get_variable('webp_dep'),
    libwebp_p.get_variable('webpdecoder_dep'),
    libwebp_p.get_variable('webpdemux_dep'),
]

if get_option('jxl')
    deps += [
        libjxl_p.dependency('jxl'),
        libjxl_p.dependency('jxl_threads')
    ]
    
    if cpp.get_id() == 'msvc'
        add_project_arguments('/DHAS_JXL', language: 'cpp')
    else
        add_project_arguments('-DHAS_JXL', language: 'cpp')
    endif
    
    c3_flags += '-DHAS_JXL'
endif

# Vendored Headers
headers = {
    'nuklear.h': 'https://raw.githubusercontent.com/OpenPNGStudio/Nuklear' /
        'refs/heads/master/nuklear.h',
    'raylib-nuklear.h': 'https://raw.githubusercontent.com/OpenPNGStudio' /
        'raylib-nuklear/refs/heads/master/include/raylib-nuklear.h',
    'miniaudio.h': 'https://raw.githubusercontent.com/mackron/miniaudio' /
        'master/miniaudio.h',
    'stb_image.h': 'https://raw.githubusercontent.com/nothings/stb/refs/heads' /
        'master/stb_image.h',
    'fontstash.h': 'https://raw.githubusercontent.com/memononen/fontstash' /
        'refs/heads/master/src/fontstash.h'
}

foreach name, url : headers
    file = here / 'include/vendor' / name
    if not fs.exists(file)
        message('Downloading ' + file)
        run_command(curl, '-L', '-o', file, url, check: true)
    else
        message('File ' + name + ' exists')
    endif
endforeach

# Additional Patches
patches = {
    'fontstash-remove-stb.patch': 'include/vendor/fontstash.h'
}

foreach ptch, to_patch : patches
    file = here / 'subprojects/packagefiles' / ptch
    run_command(patch, '-N', '-i', file, here / to_patch, check: false)
endforeach

# libportal
if host_machine.system() == 'linux'
    libportal_p = subproject('libportal', default_options: {
        'default_library': 'static',
        'backend-gtk3': 'disabled',
        'backend-gtk4': 'disabled',
        'backend-qt5': 'disabled',
        'backend-qt6': 'disabled',
        'introspection': false,
        'vapi': false,
        'docs': false,
        'tests': false
    })
    
    deps += libportal_p.get_variable('libportal_dep')
    
    xml = wl.find_protocol('xdg-foreign',
        state : 'unstable',
        version : 1,
    )
    
    xdg_foreign = wl.scan_xml(xml)
    
    sources += xdg_foreign
    deps += dependency('wayland-client')
    includes += libportal_p.get_variable('libportal_inc')
endif
