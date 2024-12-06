COMMENT = Create & stream PNGTuber models with ease
VERSION = 0.1.0
DISTNAME = openpngstudio
SITES = https://codeberg.org/LowByteFox/OpenPNGStudio/archive/
HOMEPAGE = https://codeberg.org/LowByteFox/OpenPNGStudio
CATEGORIES = multimedia graphics
DISTFILES = c36f289.tar.gz
FULLPKGNAME = ${DISTNAME}-${VERSION}

BUILD_DEPENDS += devel/meson \
				 devel/ninja \
				 devel/cmake \
				 devel/git \
				 net/curl

# EUPL-1.2
PERMIT_PACKAGE = Yes

# Since the default meson.port.mk doesn't allow downloading wrap files
# I had to make some adjustments, couldn't use meson module
# I have no idea what I'm doing here, I'll improve it

DPB_PROPERTIES += noconfigurejunk

SEPARATE_BUILD ?= Yes

# from ${LOCALBASE}/bin/meson:
# Warn if the locale is not UTF-8. This can cause various unfixable issues
# such as os.stat not being able to decode filenames with unicode in them.
# There is no way to reset both the preferred encoding and the filesystem
# encoding, so we can just warn about it.
CONFIGURE_ENV += LC_CTYPE="en_US.UTF-8"
MAKE_ENV += LC_CTYPE="en_US.UTF-8"

# don't pick up llvm-ar(1)
CONFIGURE_ENV += AR="ar"

MODMESON_CONFIGURE_ENV += CC="${CC}" CFLAGS="${CFLAGS}" \
				CXX="${CXX}" CXXFLAGS="${CXXFLAGS}"

# SHARED_LIBS: default to '0.0' if unset
MODMESON_CONFIGURE_ENV += MODMESON_PORT_BUILD=yes

MODMESON_CONFIGURE_ARGS += --buildtype=plain \
						   --prefix "${PREFIX}" \
						   --mandir="${PREFIX}/man" \
						   --sysconfdir="${SYSCONFDIR}" \
						   --localstatedir="${LOCALSTATEDIR}" \
						   --sharedstatedir="/var/db" \
						   --auto-features=enabled

MODMESON_CONFIGURE_ENV += TERM="dumb"

CONFIGURE_ARGS += ${MODMESON_CONFIGURE_ARGS}
CONFIGURE_ENV += ${MODMESON_CONFIGURE_ENV}

do-configure:
	exec ${SETENV} ${CONFIGURE_ENV} ${LOCALBASE}/bin/meson setup \
		${CONFIGURE_ARGS} ${WRKSRC} ${WRKBUILD}

do-build:
	exec ${SETENV} ${MAKE_ENV} \
		${LOCALBASE}/bin/meson compile -C ${WRKBUILD} -v -j ${MAKE_JOBS}

do-install:
	exec ${SETENV} ${MAKE_ENV} ${FAKE_SETUP} \
		${LOCALBASE}/bin/meson install --no-rebuild -C ${WRKBUILD}

.include <bsd.port.mk>

