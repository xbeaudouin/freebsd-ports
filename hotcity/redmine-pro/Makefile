# $FreeBSD$

PORTNAME=       redmine-pro
PORTVERSION=    1.0.0
CATEGORIES=     www
MASTER_SITES=	http://wpad.home.oav.net/kiwi/

MAINTAINER=     xbeaudouin@hotcity.lu
COMMENT=        Redmine Additionals Plugin

LICENSE=        GPLv2

RUN_DEPENDS=	rubygem-spreadsheet>=0:textproc/rubygem-spreadsheet \
		rubygem-vcard>=0:textproc/rubygem-vcard \
		rubygem-prawn>=1:print/rubygem-prawn \
		rubygem-wicked_pdf>=1:print/rubygem-wicked_pdf \
		rubygem-rubyzip>=0:archiver/rubygem-rubyzip

NO_ARCH=        yes

REDMINE_PLUGIN_NAME=    redmine_${PORTNAME}

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
