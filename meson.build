project('OpenPNGStudio', 'c')

cmake = import('cmake')
cc = meson.get_compiler('c')

raylib_proj = cmake.subproject('raylib')
raylib = raylib_proj.dependency('raylib')

srcs = ['src/main.c']

executable('OpenPNGStudio', srcs,
  dependencies: [
    raylib,
    cc.find_library('m'),
  ],
)
