project('OpenPNGStudio', 'c')

cmake = import('cmake')
fs = import('fs')

cc = meson.get_compiler('c')
curl = find_program('curl')

raylib_proj = cmake.subproject('raylib')
raylib = raylib_proj.dependency('raylib')

message('Downloading nuklear')

foreach url : ['https://raw.githubusercontent.com/Immediate-Mode-UI/Nuklear/refs/heads/master/nuklear.h', 'https://raw.githubusercontent.com/RobLoach/raylib-nuklear/refs/heads/master/include/raylib-nuklear.h']
  file = 'include/' + fs.name(url)
  if not fs.exists(file)
    message('Downloading ' + file)
    run_command(curl, '-L', '-o', file, url, check: true)
  endif

endforeach

srcs = ['src/main.c', 'src/pathbuf.c', 'src/str.c', 'src/filedialog.c', 
  'src/nuklear.c']

executable('OpenPNGStudio', srcs,
  dependencies: [
    raylib,
    cc.find_library('m'),
  ],
  include_directories : include_directories('include/'),
)
