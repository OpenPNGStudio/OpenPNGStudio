oxy_reporter_lib = custom_target(
    'OpenPNGStudio crash reporter library',
    output: 'liboxy_reporter.' + lib_ext,
    command: [c3c, c3_opt, 'build', 'oxy_reporter', c3_flags],
    depends: [opng_lib, cli_lib], # so C3 doesn't collide when compiling
    build_always_stale: true
)

oxy_reporter_dep = declare_dependency(link_whole: oxy_reporter_lib)

oxy_reporter_src = [files('raygui.c')]

if system == 'windows'
    oxy_reporter_src += files('titlebar.c')
endif