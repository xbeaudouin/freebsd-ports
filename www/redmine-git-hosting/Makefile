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
		rubygem-dalli:databases/rubygem-dalli \
		rubygem-redis:databases/rubygem-redis \
		rubygem-hiredis:databases/rubygem-hiredis \
		rubygem-escape_utils:textproc/rubygem-escape_utils \
		rubygem-html-pipeline:textproc/rubygem-html-pipeline \
		rubygem-rinku:www/rubygem-rinku \
		rubygem-github-markup:textproc/rubygem-github-markup \
		rubygem-redcloth:www/rubygem-redcloth \
		rubygem-org-ruby:textproc/rubygem-org-ruby \
		rubygem-creole:textproc/rubygem-creole \
		rubygem-asciidoctor:textproc/rubygem-asciidoctor \
		rubygem-sidekiq:devel/rubygem-sidekiq \
		rubygem-sshkey:security/rubygem-sshkey

NO_ARCH=        yes

USE_GITHUB=     yes
GH_ACCOUNT=     jbox-web
GH_PROJECT=	redmine_git_hosting
#GH_TAGNAME=     a625da4

REDMINE_PLUGIN_NAME=    redmine_${PORTNAME}

.include "${.CURDIR}/../../www/redmine4/bsd.redmine.mk"
