# $FreeBSD$

PORTNAME=	circle_theme
DISTVERSION=	2.1.5
PORTREVISION=	1
CATEGORIES=	www
DISTNAME=	${PORTNAME}-2_1_5
MASTER_SITES=	http://wpad.home.oav.net/kiwi/r/

WRKSRC=		${WRKDIR}/circle

MAINTAINER=	kiwi@oav.net
COMMENT=	Redmine Circle Theme

LICENSE=	NONE

USES=		zip

NO_BUILD=	yes
NO_ARCH=	yes

do-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/www/redmine/public/themes/circle
	@cd ${WRKSRC} && \
		${COPYTREE_SHARE} "*" ${STAGEDIR}${PREFIX}/www/redmine/public/themes/circle

.include <bsd.port.mk>
