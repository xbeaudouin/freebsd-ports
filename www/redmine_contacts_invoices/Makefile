# $FreeBSD$

PORTNAME=       redmine_contacts_invoices
PORTVERSION=    4.2.3
DISTNAME=	${PORTNAME}-4_2_3-pro
CATEGORIES=     www
MASTER_SITES=	http://wpad.home.oav.net/kiwi/r/

WRKSRC=		$(WRKDIR)/${PORTNAME}

MAINTAINER=     xbeaudouin@hotcity.lu
COMMENT=        Redmine Additionals Plugin

LICENSE=        GPLv2

RUN_DEPENDS=	rubygem-prawn>=1:print/rubygem-prawn \
		rubygem-wicked_pdf>=1:print/rubygem-wicked_pdf \
		rubygem-rubyzip>=0:archivers/rubygem-rubyzip

NO_ARCH=        yes

REDMINE_PLUGIN_NAME=    redmine_${PORTNAME}

USES=		zip

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
