PORTNAME=	jwt-cpp
DISTVERSIONPREFIX=	v
DISTVERSION=	0.7.1
PORTREVISION=	2
CATEGORIES=	devel
MASTER_SITES=	https://github.com/Thalhammer/jwt-cpp/releases/download/${DISTVERSIONFULL}/

MAINTAINER=	kiwi@FreeBSD.org
COMMENT=	Header only library for creating and validating JSON web tokens in C++
WWW=		https://thalhammer.github.io/jwt-cpp/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

USES=		cmake

NO_WRKSUBDIR=	yes

CMAKE_OFF=	JWT_BUILD_EXAMPLES
CMAKE_ON=	DISABLE_JWP_CPP_PICOJSON \
		JWT_DISABLE_PICOJSON
CMAKE_ARGS=	-DJWT_CMAKE_FILES_INSTALL_DIR:STRING="lib/cmake/${PORTNAME}"

.include <bsd.port.mk>
