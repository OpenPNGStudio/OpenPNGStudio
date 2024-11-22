project('OpenPNGStudio', 'c')

cmake = import('cmake')
fs = import('fs')

cc = meson.get_compiler('c')
curl = find_program('curl')

raylib_proj = cmake.subproject('raylib')
raylib = raylib_proj.dependency('raylib')

libuv_proj = subproject('libuv')
libuv = libuv_proj.get_variable('libuv_dep')

message('Downloading nuklear')

headers = ['https://raw.githubusercontent.com/Immediate-Mode-UI/Nuklear/refs/heads/master/nuklear.h', 'https://raw.githubusercontent.com/RobLoach/raylib-nuklear/refs/heads/master/include/raylib-nuklear.h']

if host_machine.system() == 'windows'
  headers += 'https://raw.githubusercontent.com/raylib-extras/extras-c/refs/heads/main/raylib_win32.h'
endif

foreach url : headers
  file = 'include/' + fs.name(url)
  if not fs.exists(file)
    message('Downloading ' + file)
    run_command(curl, '-L', '-o', file, url, check: true)
  endif
endforeach

srcs = ['src/main.c', 'src/pathbuf.c', 'src/str.c', 'src/filedialog.c', 
  'src/nuklear.c', 'src/messagebox.c', 'src/console.c', 'src/layermgr.c',
  'src/editor.c', 'src/line_edit.c']

deps = [raylib, libuv, cc.find_library('m')]

if host_machine.system() == 'windows'
  deps += cc.find_library('winmm')
endif

executable('OpenPNGStudio', srcs,
  dependencies: deps,
  include_directories : include_directories('include/'),
)
