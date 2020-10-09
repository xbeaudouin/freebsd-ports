# Created by: Xavier Beaudouin <kiwi@oav.net>
# $FreeBSD$

PORTNAME=       additionals
PORTVERSION=    2.0.24
CATEGORIES=     www
PKGNAMEPREFIX=  redmine-

MAINTAINER=     kiwi@oav.net
COMMENT=        Redmine Additionals Plugin

LICENSE=        GPLv2

RUN_DEPENDS=	rubygem-deface>=1.5:devel/rubygem-deface \
		rubygem-gemoji>=3:textproc/rubygem-gemoji
# GEM invisible_captcha et slim-rails a faire

NO_ARCH=        yes

USE_GITHUB=     yes
GH_ACCOUNT=     AlphaNodes
GH_PROJECT=	additionals
GH_TAGNAME=     058e1f7

REDMINE_PLUGIN_NAME=    redmine_${PORTNAME}

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
