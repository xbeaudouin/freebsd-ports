PORTNAME=	linphone
PORTVERSION=	6.1.1
PORTEPOCH=	1
CATEGORIES=	net
EXTRACT_ONLY=	${DISTNAME}${EXTRACT_SUFX}

MAINTAINER=	hiroo.ono+freebsd@gmail.com
COMMENT=	SIP client supporting voice/video calls and text messaging
WWW=		https://www.linphone.org/

LICENSE=	GPLv3

LIB_DEPENDS=	libbctoolbox.so:net/bctoolbox \
		liblinphone++.so:net/liblinphone \
		libmediastreamer2.so:net/mediastreamer \
		libortp.so:net/ortp \
		libxml2.so:textproc/libxml2 \
		liblime.so:security/lime \
		libjsoncpp.so:devel/jsoncpp \
		libbelle-sip.so:net/belle-sip \
		libbelr.so:textproc/belr

USES=		cmake compiler:c++17-lang gl pkgconfig qt:6 tar:bzip2 xorg sqlite:3
USE_GITLAB=	yes
GL_SITE=	https://gitlab.linphone.org/BC
GL_ACCOUNT=	public
GL_PROJECT=	linphone-desktop
GL_TAGNAME=	${PORTVERSION}
USE_GL+=	gl opengl
USE_QT+=	base declarative networkauth svg tools
USE_XORG=	x11

CMAKE_ARGS+=	-DCMAKE_INSTALL_RPATH="${LOCALBASE}/lib/linphone" \
		-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=NO \
		-DLINPHONEAPP_INSTALL_PREFIX=${PREFIX} \
		-DLINPHONEAPP_VERSION="${PORTVERSION}" \
		-DGIT_EXECUTABLE=NO
CMAKE_ON=	ENABLE_VIDEO \
		ENABLE_BUILD_VERBOSE
CMAKE_OFF=	ENABLE_APP_PACKAGE_ROOTCA \
		ENABLE_BUILD_APP_PLUGINS

ICONDIR=	${LOCALBASE}/share/icons/hicolor

post-install:
	 ${INSTALL_DATA} ${FILESDIR}/linphone.desktop \
   		 ${STAGEDIR}${LOCALBASE}/share/applications/linphone.desktop
	 ${MKDIR} ${STAGEDIR}${ICONDIR}/scalable/apps
	 ${INSTALL_DATA} ${WRKSRC}/Linphone/data/image/linphone.svg \
		 ${STAGEDIR}${ICONDIR}/scalable/apps/linphone.svg

.include <bsd.port.mk>
