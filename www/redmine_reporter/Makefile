# $FreeBSD$

PORTNAME=       redmine_reporter
PORTVERSION=    1.0.3
DISTNAME=	${PORTNAME}-1_0_3-pro
CATEGORIES=     www
MASTER_SITES=	http://wpad.home.oav.net/kiwi/r/

WRKSRC=		$(WRKDIR)/${PORTNAME}

MAINTAINER=     xbeaudouin@hotcity.lu
COMMENT=        Redmine Additionals Plugin

LICENSE=        NONE

RUN_DEPENDS=	rubygem-wicked_pdf>=1:print/rubygem-wicked_pdf \
		rubygem-rubyzip>=0:archivers/rubygem-rubyzip

NO_ARCH=        yes

REDMINE_PLUGIN_NAME=    ${PORTNAME}

USES=		zip

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
