COMMENT = Create & stream PNGTuber models with ease
DISTVERSION = 0.1.0
PORTNAME = openpngstudio
MASTER_SITES = https://codeberg.org/LowByteFox/OpenPNGStudio/archive/
WWW = https://codeberg.org/LowByteFox/OpenPNGStudio
CATEGORIES = multimedia graphics
DISTFILES = c36f289.tar.gz
DISTNAME = openpngstudio
FULLPKGNAME = ${DISTNAME}-${VERSION}
MAINTAINER = LowByteFox lowbytefox@noreply.codeberg.org

BUILD_DEPENDS = meson:devel/meson \
				ninja:devel/ninja \
				cmake:devel/cmake \
				git:devel/git \
				curl:ftp/curl

USE_GL = glu opengl
USE_LDCONFIG = yes
USE_XORG = ice sm x11 xcursor xext xi xinerama xrandr xxf86vm

LICENSE = EUPL-1.2
LICENSE_NAME = EUROPEAN UNION PUBLIC LICENCE v. 1.2
LICENSE_FILE = ${WRKSRC}/LICENSE
LICENSE_PERMS = dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

USES = meson

.include <bsd.port.mk>
