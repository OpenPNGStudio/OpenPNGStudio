project(
    'OpenPNGStudio',
    'c',
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

# Dependencies
raylib_o = cmake.subproject_options()
raylib_o.add_cmake_defines(
    {
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
    },
)

raylib_p = cmake.subproject('raylib', options: raylib_o)
sqlite_p = subproject('sqlite3', default_options: ['default_library=static'])

raylib = raylib_p.dependency('raylib')
sqlite = sqlite_p.get_variable('sqlite3_dep')


# Headers
vendor_headers = [
    'https://raw.githubusercontent.com/OpenPNGStudio/Nuklear/refs/heads/master/nuklear.h',
    'https://raw.githubusercontent.com/OpenPNGStudio/raylib-nuklear/refs/heads/master/include/raylib-nuklear.h',
    'https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h',
    'https://raw.githubusercontent.com/raysan5/raygui/refs/heads/master/src/raygui.h',
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

c3_target_version = '0.7.10'
c3_target_hash = '1a3cdc01ecb6165669cdb3c53660aafb6d001103'

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

# C3 project
target = 'OpenPNGStudio-linux-x64'
ext = 'a'

if host_machine.system() == 'windows'
    ext = 'lib'
    target = 'OpenPNGStudio-windows-x64'
endif

lib = custom_target(
    'OpenPNGStudio C3 library',
    output: 'libOpenPNGStudio.' + ext,
    command: [c3c, 'build', target, '--warn-deprecation=no'],
    build_always_stale: true,
)

opng = declare_dependency(link_with: lib)

# C part
src = ['src/wrappers.c', 'src/core/brain_damage.c', 'src/core/microphone.c']
extra_libs = []

if host_machine.system() == 'windows'
    add_project_arguments(['/wd5105', '/experimental:c11atomics'], language: 'c')
    foreach winlib : ['Shlwapi', 'Dbghelp']
        extra_libs += cc.find_library(winlib)
    endforeach

    windows = import('windows')
    src += windows.compile_resources('data/win.rc')
endif

executable(
    'OpenPNGStudio',
    src,
    dependencies: [raylib, sqlite, opng, extra_libs],
    include_directories: ['include/', 'include/vendor/'],
    install: true,
    install_dir: 'bin',
    win_subsystem: 'windows',
)

# Install
install_subdir(
    'assets',
    install_dir: 'share/OpenPNGStudio',
    exclude_files: ['assets/Oxy/refsheet.png'],
    strip_directory: true
)

install_subdir(
    'licenses',
    install_dir: 'share/OpenPNGStudio',
)

install_data(
    'assets/logo.png',
    install_dir: 'share/icons/hicolor/512x512/apps',
    rename: 'openpngstudio.png'
)

install_data(
    'data/dev.lowbytefox.OpenPNGStudio.metainfo.xml',
    install_dir: 'usr/share/metainfo'
)

install_data(
    'data/dev.lowbytefox.OpenPNGStudio.desktop',
    install_dir: 'share/applications'
)

# Note: when installing use --skip-subprojects

# Validate MetaInfo file
if ascli.found()
    test('validate metainfo file',
        ascli,
        args: [
            'validate',
            '--no-net',
            '--pedantic',
            'data/dev.lowbytefox.OpenPNGStudio.metainfo.xml'
        ],
        workdir: meson.project_source_root()
    )
endif
