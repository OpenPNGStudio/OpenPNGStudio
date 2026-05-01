opng_lib = custom_target(
    'OpenPNGStudio opng cli',
    output: 'libopng.' + ext,
    command: [c3c, 'build', 'opng', '--warn-deprecation=no'],
)

opng_dep = declare_dependency(link_with: opng_lib)

opng_c_srcs = ['src/loaders/avif.c', 'src/loaders/jpeg_xl.cpp', 
    'src/loaders/webp.c']
