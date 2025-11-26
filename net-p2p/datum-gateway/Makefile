PORTNAME=	datum_gateway
DISTVERSIONPREFIX=	v
DISTVERSION=	0.4.0
DISTVERSIONSUFFIX=	beta
CATEGORIES=	net-p2p

MAINTAINER=	kiwi@FreeBSD.org
COMMENT=	Gateway for true solo mining
WWW=		https://github.com/OCEAN-xyz/datum_gateway

LICENSE=	GPLv3
LICENSE_FILE=	${WRKSRC}/LICENSE

LIB_DEPENDS=	libcurl.so:ftp/curl \
		libjansson.so:devel/jansson \
		libsodium.so:security/libsodium \
		libmicrohttpd.so:www/libmicrohttpd \
		libargp.so:devel/argp-standalone \
		libepoll-shim.so:devel/libepoll-shim

USES=		cmake pkgconfig
USE_GITHUB=	yes
GH_ACCOUNT=	OCEAN-xyz
GH_PROJECT=	datum_gateway

.include <bsd.port.mk>
