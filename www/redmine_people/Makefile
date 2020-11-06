# $FreeBSD$

PORTNAME=       redmine_people
PORTVERSION=    1.5.2
DISTNAME=	${PORTNAME}-1_5_2-pro
CATEGORIES=     www
MASTER_SITES=	http://wpad.home.oav.net/kiwi/r/

WRKSRC=		$(WRKDIR)/${PORTNAME}

MAINTAINER=     xbeaudouin@hotcity.lu
COMMENT=        Redmine Additionals Plugin

LICENSE=        GPLv2

RUN_DEPENDS=	rubygem-vcard>=0:textproc/rubygem-vcard

NO_ARCH=        yes

REDMINE_PLUGIN_NAME=    redmine_${PORTNAME}

USES=		zip

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
