# Created by: Yukihiro Nakai <nakai@FreeBSD.org>
# $FreeBSD: head/lang/mono/Makefile 507372 2019-07-26 20:46:53Z gerald $

PORTNAME=	mono
PORTVERSION=	6.8.0.96
CATEGORIES=	lang
MASTER_SITES=	https://download.mono-project.com/sources/mono/
DISTFILES=	${PORTNAME}-${PORTVERSION}${EXTRACT_SUFX}

MAINTAINER=	mono@FreeBSD.org
COMMENT=	Open source implementation of .NET Development Framework

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

ONLY_FOR_ARCHS=	amd64 armv6 armv7 i386 powerpc powerpc64

BUILD_DEPENDS=	bash:shells/bash \
		cmake>0:devel/cmake \
		p5-XML-Parser>=0:textproc/p5-XML-Parser
LIB_DEPENDS=	libinotify.so:devel/libinotify
RUN_DEPENDS=	ca_root_nss>=0:security/ca_root_nss

USES=		autoreconf bison compiler:c11 cpe gmake iconv libtool pathfix \
		perl5 python shebangfix tar:xz
USE_LDCONFIG=	yes
USE_PERL5=	build

SHEBANG_FILES=	mono/mini/genmdesc.py mono/tests/test_lldb.py \
		scripts/mono-heapviz scripts/mono-package-runtime

GNU_CONFIGURE=	yes
CONFIGURE_ARGS=	--disable-dtrace \
		--enable-btls

MAKE_ENV=	INSTALL_STRIP_FLAG="${STRIP}" \
		MONO_SHARED_DIR="${WRKDIR}" \
		TZ=UTC

CPPFLAGS+=	-I${LOCALBASE}/include

BINARY_ALIAS=	python=${PYTHON_CMD}

OPTIONS_DEFINE=		HEAPVIZ MONOLITE NLS X11
OPTIONS_DEFAULT=	MONOLITE X11
OPTIONS_SUB=		yes

HEAPVIZ_DESC=	Install mono-heapviz debug tool (requires py-pillow)
MONOLITE_DESC=	Use monolite to bootstrap mcs (otherwise use installed mcs)

HEAPVIZ_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}pillow>=0:graphics/py-pillow@${PY_FLAVOR}
MONOLITE_MASTER_SITES=	http://download.mono-project.com/monolite/:monolite
MONOLITE_DISTFILES=	monolite-linux-${MONOLITE_VERSION}-latest.tar.gz:monolite
NLS_USES=		gettext
NLS_CONFIGURE_OFF=	--disable-nls
X11_USES=		display:test

MONOLITE_VERSION=	1051000004

.include <bsd.port.pre.mk>

.if ${ARCH} == "powerpc" || ${ARCH} == "powerpc64"
CONFIGURE_ARGS=	--disable-btls \
		--disable-dtrace
CPPFLAGS+=	-O2 -fno-strict-aliasing -Wno-missing-declarations \
		-Wno-maybe-uninitialized -pipe -D_LARGE_FILES -D_ALL_SOURCE \
		-D_THREAD_SAFE -D_REENTRANT
PLIST_SUB+=	NO_PPC="@comment " \
		PPC=""
.else
PLIST_SUB+=	NO_PPC="" \
		PPC="@comment "
.endif

TEST_ARGS=	-k
TEST_TARGET=	check

PORTSCOUT=	limit:^\d+\.\d+\.[1-9]\d*

LOCALBASE?=	/usr/local
.if !exists(${LOCALBASE}/bin/mcs)
OPTIONS_SLAVE=	MONOLITE
.endif

post-extract-MONOLITE-on:
	${MKDIR} ${WRKSRC}/mcs/class/lib/monolite-linux
	${MV} ${WRKDIR}/monolite-linux-${MONOLITE_VERSION}-latest ${WRKSRC}/mcs/class/lib/monolite-linux/${MONOLITE_VERSION}

post-patch:
	${REINPLACE_CMD} -e 's|^#!/bin/bash|#!/usr/bin/env bash|g' \
		${WRKSRC}/scripts/mono-find-provides.in \
		${WRKSRC}/scripts/mono-find-requires.in \
		${WRKSRC}/scripts/mono-test-install
	${FIND} ${WRKSRC} -name '*.sh' | ${XARGS} ${REINPLACE_CMD} \
		-e 's|^#!/bin/bash|#!/bin/sh|g'
	${SED} 's/tarball/${PORTVERSION}/' ${WRKSRC}/mono/mini/Makefile.am.in \
		> ${WRKSRC}/mono/mini/Makefile.am
	${REINPLACE_CMD} -e 's|/usr/share|${PREFIX}|g' \
		${WRKSRC}/mcs/class/corlib/System/Environment.cs \
		${WRKSRC}/external/corefx/src/System.Runtime.Extensions/src/System/Environment.Unix.cs
	${REINPLACE_CMD} -e 's|/usr/share/.mono|${PREFIX}/share/mono|g' \
		${WRKSRC}/man/mono-configuration-crypto.1 \
		${WRKSRC}/man/mono.1 \
		${WRKSRC}/man/mozroots.1

post-configure:
	${REINPLACE_CMD} -e 's|share\/man|man|g' \
		${WRKSRC}/mcs/jay/Makefile

post-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/mono

.include <bsd.port.post.mk>
