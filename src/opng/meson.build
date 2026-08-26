cli_lib = custom_target(
    'OpenPNGStudio cli library',
    output: 'libopng.' + lib_ext,
    command: [c3c, c3_opt, 'build', 'opng', c3_flags],
    depends: [opng_lib], # so C3 doesn't collide when compiling
    build_always_stale: true
)

cli_dep = declare_dependency(link_with: cli_lib)

opng_src = files('../loaders/avif.c', '../loaders/jpeg_xl.cpp',
    '../loaders/webp.c', '../loaders/gif.c')
