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
    meson_version: '>= 1.8.0',
    default_options: {
        'c_std': 'c17',
        'cpp_std': 'c++20'
    }
)

# Variables
here = meson.current_source_dir()
system = host_machine.system()

sources = []
deps = []
includes = []
libs = []

c3_flags = ['--warn-deprecation=no']

c3_buildtypes = {
    'debug': ['-O0', '-g'],
    'debugoptimized': ['-O3', '-g'],
    'release': ['-O3', '-g0'],
    'minsize': ['-Os', '-g0']
}

c3_opt = c3_buildtypes.get(get_option('buildtype'), ['-O0', '-g'])

lib_ext = 'a'

if system == 'windows'
    lib_ext = 'lib'
    add_project_arguments('/wd5105', '/experimental:c11atomics', language: 'c')
endif

# Imports
cmake = import('cmake')
fs = import('fs')

if system == 'linux'
    wl = import('wayland')
endif

if system == 'windows'
    windows = import('windows')
endif

# Programs
cc = meson.get_compiler('c')
cpp = meson.get_compiler('cpp')
curl = find_program('curl')
c3c = find_program('c3c')
patch = find_program('patch')
ascli = find_program('appstreamcli', required: false)
nasm = find_program('nasm', required: false)

assert(c3c.version() == '0.7.11')

# Dependencies
subdir('deps')

# Assets and asset cooker
subdir('assets')

# OpenPNGStudio and opng
subdir('src')
executable(
    'OpenPNGStudio',
    [src, sources],
    dependencies: [deps, opng_dep, libs],
    include_directories: ['include', 'include/vendor', includes],
    install: true,
    install_dir: 'bin',
    win_subsystem: 'windows',
)

if system != 'windows'
    subdir('src/opng')

    executable(
        'opng',
        opng_src,
        dependencies: [deps, cli_dep],
        include_directories: ['include'],
        install: true,
        install_dir: 'bin',
        win_subsystem: 'console',
        c_args: ['-DOPNG_STANDALONE'],
        cpp_args: ['-DOPNG_STANDALONE']
    )
endif

# Install
subdir('licenses')
subdir('data')

# Note: meson install --no-rebuild --destdir _install -C build --skip-subprojects
