# $FreeBSD$

PORTNAME=	a1_theme
DISTVERSION=	3.0.0
CATEGORIES=	www
DISTNAME=	${PORTNAME}-3_0_0
MASTER_SITES=	http://wpad.home.oav.net/kiwi/r/

WRKSRC=		${WRKDIR}/a1

MAINTAINER=	kiwi@oav.net
COMMENT=	Redmine A1 Theme

LICENSE=	NONE

USES=		zip

NO_BUILD=	yes
NO_ARCH=	yes

do-install:
	@${MKDIR} ${STAGEDIR}${PREFIX}/www/redmine/themes/a1
	@cd ${WRKSRC} && \
		${COPYTREE_SHARE} "*" ${STAGEDIR}${PREFIX}/www/redmine/themes/a1

.include <bsd.port.mk>
