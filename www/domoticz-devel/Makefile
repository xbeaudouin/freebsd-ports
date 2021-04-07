# $FreeBSD$

PORTNAME=	domoticz-devel
PORTVERSION=	2020.2.${DOMOTICZ_REL}
CATEGORIES=	www

MAINTAINER=	kiwi@oav.net
COMMENT=	Home Automation System (Development Branch)

LICENSE=	GPLv3
LICENSE_FILE=	${WRKSRC}/License.txt

LIB_DEPENDS=	libcurl.so:ftp/curl \
		libopenzwave.so:comms/openzwave-devel \
		libjsoncpp.so:devel/jsoncpp \
		libminizip.so:archivers/minizip \
		libmosquitto.so:net/mosquitto
BUILD_DEPENDS=	cereal>=1.2.2:devel/cereal

USES=		cmake pkgconfig ssl sqlite lua:53

CONFLICTS_INSTALL?=	domoticz-[234]*

OPTIONS_SUB=	YES
OPTIONS_DEFINE=	SSSL SBOOST PYTHON TELLDUS PRECOMP
OPTIONS_DEFAULT=	PYTHON PRECOMP
SBOOST_DESC=	Use static Boost instead of dynamic linking
SSSL_DESC=	Use static OpenSSL library instead of dynamic linking
PYTHON_DESC=	Enable support for Python Plugins
TELLDUS_DESC=	Enable support for Telldus
PRECOMP_DESC=	Enable usage of precompiled header to speed build time

.include <bsd.port.options.mk>

# This hack is to get rid of dependency of git while building
# the package.
DOMOTICZ_REL=	13148
DOMOTICZ_TS=	1617777149
USE_GITHUB=	yes
GH_ACCOUNT=	domoticz
GH_PROJECT=	domoticz
GH_TAGNAME=	77b0e9873

USE_RC_SUBR=	domoticz

USERS=		domoticz
GROUPS=		domoticz

CMAKE_ARGS+=	-DCMAKE_INSTALL_PREFIX=${PREFIX}/domoticz \
		-DGIT_SUBMODULE="NO" \
		-DUSE_LUA_STATIC="NO" \
		-DUSE_STATIC_OPENZWAVE="NO" \
		-DUSE_BUILTIN_SQLITE="NO" \
		-DUSE_BUILTIN_MQTT="NO" \
		-DUSE_BUILTIN_JSONCPP="NO" \
		-DUSE_BUILTIN_MINIZIP="NO"

.if ${PORT_OPTIONS:MSSSL}
CMAKE_ARGS+=	-DUSE_OPENSSL_STATIC="YES"
.else
CMAKE_ARGS+=	-DUSE_OPENSSL_STATIC="NO"
.endif

.if ${PORT_OPTIONS:MSBOOST}
CMAKE_ARGS+=	-DUSE_STATIC_BOOST="YES"
BUILD_DEPENDS+=	boost-libs>=0:devel/boost-libs
.else
CMAKE_ARGS+=	-DUSE_STATIC_BOOST="NO"
LIB_DEPENDS+=	libboost_system.so:devel/boost-libs
.endif

.if ${PORT_OPTIONS:MPYTHON}
CMAKE_ARGS+=	-DUSE_PYTHON="YES"
USES+=		python:3.5+
.else
CMAKE_ARGS+=	-DUSE_PYTHON="NO"
.endif

.if ${PORT_OPTIONS:MTELLDUS}
LIB_DEPENDS+=	libtelldus-core.so:comms/telldus-core
.endif

.if ${PORT_OPTIONS:MPRECOMP}
CMAKE_ARGS+=	-DUSE_PRECOMPILED_HEADER="YES"
.else
CMAKE_ARGS+=	-DUSE_PRECOMPILED_HEADER="NO"
.endif

post-patch:
	@${REINPLACE_CMD} -e "s,\/opt,${PREFIX},g" ${WRKSRC}/CMakeLists.txt
	@${REINPLACE_CMD} -e "s,XXXPREFIXXXX,${PREFIX}/domoticz,g" ${WRKSRC}/CMakeLists.txt
	@${REINPLACE_CMD} -e "/^ADD_PRECOMPILED_HEADER/ d" ${WRKSRC}/CMakeLists.txt
	@${REINPLACE_CMD} -e "s/\(#define APPVERSION\)\(.*\)/\1 ${DOMOTICZ_REL}/" ${WRKSRC}/appversion.h
	@${REINPLACE_CMD} -e "s/\(#define APPHASH\)\(.*\)/\1 \"${GH_TAGNAME}\"/" ${WRKSRC}/appversion.h
	@${REINPLACE_CMD} -e "s/\(#define APPDATE\)\(.*\)/\1 ${DOMOTICZ_TS}/" ${WRKSRC}/appversion.h

post-install:
	${MKDIR} ${STAGEDIR}/var/db/domoticz ${STAGEDIR}/var/run/domoticz

.include <bsd.port.mk>
