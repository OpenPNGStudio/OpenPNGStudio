ext = 'a'

if host_machine.system() == 'windows'
    ext = 'lib'
endif

app_lib = custom_target(
    'OpenPNGStudio C3 library',
    output: 'libOpenPNGStudio.' + ext,
    command: [c3c, 'build', 'OpenPNGStudio', '--warn-deprecation=no'],
    build_always_stale: true,
)

app_dep = declare_dependency(link_with: app_lib)

# C & C++ part
c_src = ['src/wrappers.c', 'src/core/brain_damage.c', 'src/core/microphone.c', 
    'src/loaders/avif.c', 'src/loaders/jpeg_xl.cpp', 'src/loaders/webp.c',
    'src/ui/filedialogs/xdp.c']

if host_machine.system() == 'windows'
    add_project_arguments(['/wd5105', '/experimental:c11atomics'], language: 'c')
    foreach winlib : ['Shlwapi', 'Dbghelp']
        extra_libs += cc.find_library(winlib)
    endforeach

    windows = import('windows')
    src += windows.compile_resources('data/win.rc')
endif
