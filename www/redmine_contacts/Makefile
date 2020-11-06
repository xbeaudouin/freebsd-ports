# $FreeBSD$

PORTNAME=       redmine_contacts
PORTVERSION=    4.3.2
DISTNAME=	${PORTNAME}-4_3_2-pro
CATEGORIES=     www
MASTER_SITES=	http://wpad.home.oav.net/kiwi/r/

MAINTAINER=     xbeaudouin@hotcity.lu
COMMENT=        Redmine Additionals Plugin

LICENSE=        GPLv2

RUN_DEPENDS=	rubygem-spreadsheet>=0:textproc/rubygem-spreadsheet \
		rubygem-vcard>=0:textproc/rubygem-vcard 

NO_ARCH=        yes

REDMINE_PLUGIN_NAME=    redmine_${PORTNAME}

USES=		zip

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
