PORTNAME=	ckpool
DISTVERSION=	0.9.9
PORTREVISION=	0
CATEGORIES=	net-p2p

MAINTAINER=	ports@FreeBSD.org
COMMENT=	Solo Bitcoin mining pool server with merged mining support
WWW=		https://bitbucket.org/ckolivas/ckpool

LICENSE=	GPLv3
LICENSE_FILE=	${WRKSRC}/COPYING

LIB_DEPENDS=	libjansson.so:devel/jansson

USES=		autoreconf:build ssl

USE_BITBUCKET=	yes
BB_ACCOUNT=	ckolivas
BB_PROJECT=	ckpool
BB_TAGNAME=	ckpool-${DISTVERSION}

GNU_CONFIGURE=		yes
GNU_CONFIGURE_MANPREFIX=	${PREFIX}/share
CONFIGURE_ARGS=		--with-openssl=${OPENSSLBASE}

USERS=		ckpool
GROUPS=		ckpool

USE_RC_SUBR=	ckpool

OPTIONS_DEFINE=		DOCS EXAMPLES
OPTIONS_DEFAULT=	DOCS

DOCS_BUILD_DEPENDS=	asciidoc:textproc/asciidoc

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
	${INSTALL_DATA} ${WRKSRC}/doc/ckpool.conf \
		${STAGEDIR}${PREFIX}/etc/ckpool/ckpool.conf.sample
	${MKDIR} ${STAGEDIR}${PREFIX}/var/log/ckpool
	${MKDIR} ${STAGEDIR}${PREFIX}/var/run/ckpool

do-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/README.md \
		${STAGEDIR}${DOCSDIR}/README.md

do-install-EXAMPLES-on:
	${MKDIR} ${STAGEDIR}${EXAMPLESDIR}
	${INSTALL_DATA} ${WRKSRC}/doc/ckpool.conf \
		${STAGEDIR}${EXAMPLESDIR}/ckpool.conf.sample

.include <bsd.port.mk>
