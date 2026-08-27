libcooker = static_library('cooker', 'cooker/loader.c',
    include_directories: '../include/vendor'
)

cooker = custom_target('cooker',
    command: [c3c, 'compile', '@INPUT@', '-o', '@OUTPUT@', '-l', libcooker,
        '--libdir', here / 'lib', '--lib', 'patterngen'],
    output: 'cooker',
    depends: [libcooker],
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
