# $FreeBSD: head/net-p2p/sonarr/Makefile 430494 2017-01-03 18:28:10Z feld $

PORTNAME=	jackett
PORTVERSION=	0.7.1225
CATEGORIES=	net-p2p
MASTER_SITES=	https://github.com/Jackett/Jackett/releases/download/
DISTNAME=	v${PORTVERSION}/Jackett.Binaries.Mono

MAINTAINER=	kiwi@oav.net
COMMENT=	Torznab proxy

LICENSE=	GPLv2

RUN_DEPENDS=	mono>0:lang/mono
LIB_DEPENDS=	libcurl.so:ftp/curl

USE_RC_SUBR=	jackett

NO_BUILD=	YES
WRKSRC=		${WRKDIR}/Jackett

#USERS=	jackett
USERS=	nobody

.include <bsd.port.options.mk>

do-install:
	${INSTALL} -d -m 755 ${STAGEDIR}/${DATADIR}
	cd ${WRKSRC} && ${COPYTREE_SHARE} \* ${STAGEDIR}/${DATADIR}

.include <bsd.port.mk>
