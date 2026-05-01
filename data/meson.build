install_data(
    'dev.lowbytefox.OpenPNGStudio.metainfo.xml',
    install_dir: 'usr/share/metainfo'
)

install_data(
    'dev.lowbytefox.OpenPNGStudio.desktop',
    install_dir: 'share/applications'
)

# Validate MetaInfo file
if ascli.found()
    test('validate metainfo file',
        ascli,
        args: [
            'validate',
            '--no-net',
            '--pedantic',
            'dev.lowbytefox.OpenPNGStudio.metainfo.xml'
        ],
        workdir: meson.project_source_root()
    )
endif
