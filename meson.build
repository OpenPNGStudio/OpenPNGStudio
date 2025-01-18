# This file is part of OpenPNGStudio. 
# Copyright (C) 2024-2025 LowByteFox
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

project('OpenPNGStudio', 'c', version: '0.1.0')

buildtype = get_option('buildtype')

if buildtype == 'release' or buildtype == 'debugoptimized'
  add_project_arguments('-DNDEBUG', language: ['c', 'cpp'])
endif

cmake = import('cmake')
fs = import('fs')

cc = meson.get_compiler('c')
curl = find_program('curl')
cp = find_program('cp')

raylib_proj = cmake.subproject('raylib')
raylib = raylib_proj.dependency('raylib')

zstd_proj = subproject('zstd', default_options: ['default_library=static'])
libzstd = zstd_proj.get_variable('libzstd_dep')

libarchive_proj = subproject('libarchive', default_options: 
  ['default_library=static', 'zstd=enabled', 'progs=[]'])
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
  'https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h',
  'https://raw.githubusercontent.com/cktan/tomlc99/refs/heads/master/toml.h']

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

message('Downloading tomlc99')
if not fs.exists('src/toml.c')
  message('Downloading toml.c')
  run_command(curl, '-L', '-o', 'src/toml.c',
    'https://raw.githubusercontent.com/cktan/tomlc99/refs/heads/master/toml.c',
    check: true)
endif

message('Copying raylib config')
run_command(cp, 'raylib_config.h', 'subprojects/raylib/src/config.h', check:  true)

srcs = ['src/main.c', 'src/pathbuf.c', 'src/str.c', 'src/filedialog.c', 
  'src/nuklear.c', 'src/ui/messagebox.c', 'src/console.c', 'src/layermgr.c',
  'src/editor.c', 'src/line_edit.c', 'src/miniaudio.c', 'src/ui/window.c', 
  'src/context.c', 'src/gif_config.c', 'src/toml.c', 'src/icon_db.c']

deps = [raylib, libunuv, libuv, cc.find_library('m'), crypto, libzstd,
  libarchive]

if host_machine.system() == 'windows'
  deps += cc.find_library('winmm')
  deps += mman
endif

if host_machine.system() == 'freebsd'
  deps += cc.find_library('iconv', dirs: ['/usr/local/lib'])
endif

executable('OpenPNGStudio', srcs,
  install: true,
  dependencies: deps,
  include_directories : include_directories('include/'),
)

install_subdir('assets', install_dir: 'share/openpngstudio')
