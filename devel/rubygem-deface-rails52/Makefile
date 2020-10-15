# $FreeBSD: head/devel/rubygem-deface/Makefile 515012 2019-10-20 17:17:43Z sunpoet $

PORTNAME=	deface
PORTVERSION=	1.5.3
CATEGORIES=	devel rubygems www
MASTER_SITES=	RG
PKGNAMESUFFIX=	-rails52

MAINTAINER=	sunpoet@FreeBSD.org
COMMENT=	Customize ERB, Haml and Slim views in a Rails application

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/MIT-LICENSE

RUN_DEPENDS=	rubygem-nokogiri>=1.6:textproc/rubygem-nokogiri \
		rubygem-polyglot>=0:devel/rubygem-polyglot \
		rubygem-rails52>=5.2:www/rubygem-rails52 \
		rubygem-rainbow>=2.1.0:devel/rubygem-rainbow

USES=		gem
USE_RUBY=	yes

NO_ARCH=	yes

.include <bsd.port.mk>
