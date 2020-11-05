# $FreeBSD: head/devel/elixir-crontab/Makefile 479406 2018-09-10 13:14:50Z mat $

PORTNAME=	teslamate
PORTVERSION=	1.20.1
DISTVERSIONPREFIX=	v
CATEGORIES=	www

MAINTAINER=	kiwi@oav.net
COMMENT=	A powerfull, self-hosted data logger for your Tesla

LICENSE=	MIT

USES=		elixir
USE_GITHUB=	yes
GH_ACCOUNT=	adriankumpf

MIX_BUILD_DEPS=	www/elixir-phoenix \
		www/elixir-phoenix_pubsub \
		www/elixir-phoenix_ecto \
		databases/elixir-postgrex \
		www/elixir-phoenix_html \
		devel/elixir-gettext 
MIX_RUN_DEPS:=	${MIX_BUILD_DEPS}
MIX_REWRITE=	yes

.include <bsd.port.mk>
