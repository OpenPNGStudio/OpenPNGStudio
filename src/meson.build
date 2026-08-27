opng_lib = custom_target(
    'OpenPNGStudio library',
    output: 'libOpenPNGStudio.' + lib_ext,
    command: [c3c, c3_opt, 'build', 'OpenPNGStudio', c3_flags],
    input: [cooked],
    build_always_stale: true
)

opng_dep = declare_dependency(link_with: opng_lib)

src = files('wrappers.c', 'core/brain_damage.c', 'core/microphone.c',
    'loaders/avif.c', 'loaders/jpeg_xl.cpp', 'loaders/webp.c',
    'ui/filedialogs/xdp.c', 'ui/filedialogs/win32.c')

if system == 'windows'
    add_project_arguments('/wd5105', '/experimental:c11atomics', language: 'c')
    
    foreach winlib : ['Shlwapi', 'Dbghelp', 'Ws2_32']
        libs += cc.find_library(winlib)
    endforeach
    
    sources += windows.compile_resources('../data/win.rc')
endif
