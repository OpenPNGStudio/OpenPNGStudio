libcooker = static_library('cooker', 'cooker/loader.c',
    include_directories: '../include/vendor',
    name_suffix: lib_ext,
)

cooker_flags = []
cooker_depends = []

if get_option('release')
    cooker_flags += ['-D', 'RELEASE_SPLASH']

    cooker_depends += fs.copyfile('banners/banner_' + meson.project_version() + '.qoi', 'banner.qoi')
endif

cooker = custom_target('cooker',
    command: [c3c, 'compile', '@INPUT@', '-o', '@OUTPUT@', '-l', libcooker,
        '--libdir', here / 'lib', '--lib', 'patterngen', cooker_flags],
    output: 'cooker',
    depends: [libcooker, cooker_depends],
    input: ['cooker/main.c3', 'cooker/atlas.c3', 'cooker/codegen.c3',
        'cooker/splash.c3'],
    build_by_default: true
)

cooked = custom_target('cooked',
    command: [cooker, '@CURRENT_SOURCE_DIR@'],
    output: ['cooked_assets.c3', 'icon_atlas.qoi', 'splash.qoi'],
    console: true,
    build_by_default: true,
    install: true,
    install_dir: [false, 'share/OpenPNGStudio', 'share/OpenPNGStudio']
)

install_subdir('fonts',
    install_dir: 'share/OpenPNGStudio'
)

install_subdir('shaders',
    install_dir: 'share/OpenPNGStudio'
)

install_subdir('Oxy',
    install_dir: 'share/OpenPNGStudio',
    exclude_files: ['Oxy/refsheet.png']
)

install_data(
    'logo.png',
    install_dir: 'share/icons/hicolor/512x512/apps',
    rename: 'openpngstudio.png'
)

install_data(
    'logo.png',
    install_dir: 'share/OpenPNGStudio'
)
