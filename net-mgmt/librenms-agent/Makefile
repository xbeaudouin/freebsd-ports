# Created by: Nicolas Goralski <nicolas@goralski.fr>
# $FreeBSD: $

PORTNAME=	librenms-agent
PORTVERSION=	0.3
CATEGORIES=	net-mgmt

MAINTAINER=	kiwi@oav.net
COMMENT=	librenms agents and plugins for freebsd system

LICENSE=	GPLv3

NO_ARCH=	yes

USE_GITHUB=	yes
GH_ACCOUNT=	librenms
GH_PROJECT=	librenms-agent
GH_TAGNAME=	dde18e9

NO_BUILD=	yes

RUN_DEPENDS+=	xinetd:security/xinetd \
		bash:shells/bash

LIB_DEPENDS+=	libstatgrab.so:devel/libstatgrab \

do-install:
	cd ${STAGEDIR} ; \
	${MKDIR} usr/local/etc/xinetd.d/ usr/local/lib/check_mk_agent/plugins usr/local/lib/check_mk_agent/repo usr/local/lib/check_mk_agent/local ; \
	cd ${WRKSRC} ; \
	${INSTALL_SCRIPT} check_mk_agent_freebsd ${STAGEDIR}/usr/local/bin/check_mk_agent ; \
	${INSTALL_SCRIPT} mk_enplug ${STAGEDIR}/usr/local/bin/ ; \
	${INSTALL_SCRIPT} check_mk_xinetd ${STAGEDIR}/usr/local/etc/xinetd.d/check_mk ; \
	${INSTALL_SCRIPT}  snmp/distro ${STAGEDIR}/usr/local/bin ; \
	for agent_local in $$( ${FIND} ./agent-local -type f ! -name README ); do \
		${INSTALL_SCRIPT} "$$agent_local" ${STAGEDIR}/usr/local/lib/check_mk_agent/repo/ ; \
	done

.include <bsd.port.mk>
