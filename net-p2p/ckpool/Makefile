PORTNAME=	ckpool
DISTVERSION=	g20250528
CATEGORIES=	net-p2p
MASTER_SITES=	https://bitbucket.org/ckolivas/ckpool/get/
DISTNAME=	${GH_TAGNAME}

MAINTAINER=	kiwi@FreeBSD.org
COMMENT=	Solo Bitcoin mining pool server with merged mining support
WWW=		https://bitbucket.org/ckolivas/ckpool

LICENSE=	GPLv3
LICENSE_FILE=	${WRKSRC}/COPYING

LIB_DEPENDS=	libjansson.so:devel/jansson

USES=		autoreconf ssl

# Commit hash
GH_TAGNAME=	968016e54004
USE_RC_SUBR=	ckpool

MASTER_SITES=	https://bitbucket.org/ckolivas/ckpool/get/
DISTNAME=	${GH_TAGNAME}

GNU_CONFIGURE=		yes
GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share
CONFIGURE_ARGS=		--with-openssl=${OPENSSLBASE}

LIB_DEPENDS+=   libepoll-shim.so:devel/libepoll-shim
CFLAGS+=        -I${LOCALBASE}/include/libepoll-shim
LDFLAGS+=       -L${LOCALBASE}/lib -lepoll-shim -lpthread

USERS=		nobody
GROUPS=		nobody

post-extract:
	${MV} ${WRKDIR}/ckolivas-${PORTNAME}-${GH_TAGNAME} ${WRKSRC}

post-patch:
	${REINPLACE_CMD} -e 's|/var/log/ckpool|${LOCALBASE}/var/log/ckpool|g' \
		${WRKSRC}/src/ckpool.c
	${REINPLACE_CMD} -e 's|/var/run/ckpool|${LOCALBASE}/var/run/ckpool|g' \
		${WRKSRC}/src/ckpool.c

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/src/ckpool \
		${STAGEDIR}${PREFIX}/bin/ckpool
	${INSTALL_PROGRAM} ${WRKSRC}/src/ckpmsg \
		${STAGEDIR}${PREFIX}/bin/ckpmsg
	${INSTALL_PROGRAM} ${WRKSRC}/src/notifier \
		${STAGEDIR}${PREFIX}/bin/ckpool-notifier
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/ckpool
	${INSTALL_DATA} ${WRKSRC}/ckpool.conf \
		${STAGEDIR}${PREFIX}/etc/ckpool/ckpool.conf.sample
	${INSTALL_DATA} ${WRKSRC}/ckpassthrough.conf \
		${STAGEDIR}${PREFIX}/etc/ckpool/ckpassthrough.conf.sample
	${INSTALL_DATA} ${WRKSRC}/ckproxy.conf \
		${STAGEDIR}${PREFIX}/etc/ckpool/ckproxy.conf.sample
	${INSTALL_DATA} ${WRKSRC}/ckpool.conf \
		${STAGEDIR}${PREFIX}/etc/ckpool/ckpool.conf.sample
	${MKDIR} ${STAGEDIR}${PREFIX}/var/log/ckpool
	${MKDIR} ${STAGEDIR}${PREFIX}/var/run/ckpool
	${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/README \
		${STAGEDIR}${DOCSDIR}/README

.include <bsd.port.mk>
