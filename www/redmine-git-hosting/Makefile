# Created by: Xavier Beaudouin <kiwi@oav.net>
# $FreeBSD$

PORTNAME=       git-hosting
PORTVERSION=    4.0.2
CATEGORIES=     www
PKGNAMEPREFIX=  redmine-

MAINTAINER=     kiwi@oav.net
COMMENT=        Redmine Git Hosting Plugin

LICENSE=        MIT

RUN_DEPENDS=	rubygem-gitlab-grack>=2.0:www/rubygem-gitlab-grack \
		rubygem-dalli>=0:databases/rubygem-dalli \
		rubygem-redis>=0:databases/rubygem-redis \
		rubygem-hiredis>=0:databases/rubygem-hiredis \
		rubygem-escape_utils>=0:textproc/rubygem-escape_utils \
		rubygem-html-pipeline>=0:textproc/rubygem-html-pipeline \
		rubygem-rinku>=0:www/rubygem-rinku \
		rubygem-github-markup>=0:textproc/rubygem-github-markup \
		rubygem-redcloth>=0:www/rubygem-redcloth \
		rubygem-org-ruby>=0:textproc/rubygem-org-ruby \
		rubygem-creole>=0:textproc/rubygem-creole \
		rubygem-asciidoctor>=0:textproc/rubygem-asciidoctor \
		rubygem-sidekiq>=0:devel/rubygem-sidekiq \
		rubygem-sshkey>=0:security/rubygem-sshkey \
		rubygem-gitolite-rugged>=0:devel/rubygem-rugged \
		rubygem-rack-parser>=0:www/rubygem-rack-parser

NO_ARCH=        yes

USE_GITHUB=     yes
GH_ACCOUNT=     jbox-web
GH_PROJECT=	redmine_git_hosting
#GH_TAGNAME=     a625da4

REDMINE_PLUGIN_NAME=    redmine_${PORTNAME}

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
