libcooker = static_library('cooker', 'cooker/loader.c',
    include_directories: '../include/vendor',
    name_suffix: lib_ext,
)

cooker_flags = []
cooker_depends = []

if release
    cooker_flags += ['-D', 'RELEASE_SPLASH']

    cooker_depends += custom_target(
        'banner.qoi',
        output: 'banner.qoi',
        command: [
            python,
            here / 'meson/copy_file.py',
            oxy_assets / 'banners/banner_' + meson.project_version() + '.qoi',
            '@OUTPUT@'
        ],
        build_always_stale: true,
        install: false,
    )
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

if system != 'windows'
    install_data(
        'logo.png',
        install_dir: 'share/icons/hicolor/96x96/apps',
        rename: 'openpngstudio.png'
    )
endif

install_data(
    'logo.png',
    install_dir: 'share/OpenPNGStudio'
)
