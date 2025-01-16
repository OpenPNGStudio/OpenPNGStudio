project('OpenPNGStudio', 'c')

cmake = import('cmake')
fs = import('fs')

cc = meson.get_compiler('c')
curl = find_program('curl')
cp = find_program('cp')

raylib_proj = cmake.subproject('raylib')
raylib = raylib_proj.dependency('raylib')

libarchive_proj = subproject('libarchive', default_options: 
  ['default_library=static', 'zstd=enabled'])
libarchive = libarchive_proj.get_variable('libarchive_dep')

libarchive = libarchive_proj.get_variable('libarchive_dep')
if host_machine.system() == 'openbsd'
  crypto = dependency('libcrypto')
else
  libressl_opt = cmake.subproject_options()
  libressl_opt.add_cmake_defines({'LIBRESSL_APPS': false})
  libressl_opt.add_cmake_defines({'LIBRESSL_TESTS': false})

  libressl_proj = cmake.subproject('libressl', options: libressl_opt)
  crypto = libressl_proj.dependency('crypto')
endif

libuv_proj = subproject('libuv', default_options: ['default_library=static', 'build_tests=false'])
libuv = libuv_proj.get_variable('libuv_dep')

libunuv_proj = subproject('libunuv', default_options: ['default_library=static'])
libunuv = libunuv_proj.get_variable('libunuv_dep')

message('Downloading nuklear')

headers = ['https://raw.githubusercontent.com/Immediate-Mode-UI/Nuklear/refs/heads/master/nuklear.h',
  'https://raw.githubusercontent.com/RobLoach/raylib-nuklear/refs/heads/master/include/raylib-nuklear.h',
  'https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h']

if host_machine.system() == 'windows'
  headers += 'https://raw.githubusercontent.com/raylib-extras/extras-c/refs/heads/main/raylib_win32.h'
  mman_proj = cmake.subproject('mman-win32')
  mman = mman_proj.dependency('mman')
endif

foreach url : headers
  file = 'include/' + fs.name(url)
  if not fs.exists(file)
    message('Downloading ' + file)
    run_command(curl, '-L', '-o', file, url, check: true)
  endif
endforeach

message('Copying raylib config')
run_command(cp, 'raylib_config.h', 'subprojects/raylib/src/config.h', check:  true)

srcs = ['src/main.c', 'src/pathbuf.c', 'src/str.c', 'src/filedialog.c', 
  'src/nuklear.c', 'src/ui/messagebox.c', 'src/console.c', 'src/layermgr.c',
  'src/editor.c', 'src/line_edit.c', 'src/miniaudio.c', 'src/ui/window.c', 
  'src/context.c', 'src/gif_config.c']

deps = [raylib, libunuv, libuv, cc.find_library('m'), crypto, libarchive]

if host_machine.system() == 'windows'
  deps += cc.find_library('winmm')
  deps += mman
endif

executable('OpenPNGStudio', srcs,
  install: true,
  dependencies: deps,
  include_directories : include_directories('include/'),
)

install_subdir('assets', install_dir: 'share/openpngstudio')
