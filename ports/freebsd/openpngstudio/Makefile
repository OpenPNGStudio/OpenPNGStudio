PORTNAME=	openpngstudio
DISTVERSION=	0.1.0
CATEGORIES=	graphics multimedia
MASTER_SITES=	https://codeberg.org/LowByteFox/OpenPNGStudio/archive/
DISTNAME=	c36f289
WRKSRC=		${WRKDIR}/${PORTNAME}

MAINTAINER=	lowbytefox@noreply.codeberg.org
COMMENT=	Create & stream PNGTuber models with ease
WWW=		https://codeberg.org/LowByteFox/OpenPNGStudio

LICENSE=	EUPL-1.2
LICENSE_NAME=	EUROPEAN UNION PUBLIC LICENCE v. 1.2
LICENSE_FILE=	${WRKSRC}/LICENSE
LICENSE_PERMS=	dist-mirror dist-sell pkg-mirror pkg-sell auto-accept

BUILD_DEPENDS=	cmake:devel/cmake \
		curl:ftp/curl \
		git:devel/git \
		meson:devel/meson \
		ninja:devel/ninja

USES=		gl meson xorg

USE_GL=		glu opengl
USE_XORG=	ice sm x11 xcursor xext xi xinerama xrandr xxf86vm

post-patch:
	${REINPLACE_CMD} -e 's,%%LOCALBASE%%,${LOCALBASE},g' ${WRKSRC}/src/main.c

.include <bsd.port.mk>
