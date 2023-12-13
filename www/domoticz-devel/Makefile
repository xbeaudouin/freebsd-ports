PORTNAME=	domoticz-devel
PORTVERSION=	2023.2.${DOMOTICZ_REL}
CATEGORIES=	www

MAINTAINER=	kiwi@oav.net
COMMENT=	Home Automation System (Development Branch)
WWW=		https://www.domoticz.com

LICENSE=	GPLv3
LICENSE_FILE=	${WRKSRC}/License.txt

LIB_DEPENDS=	libcurl.so:ftp/curl \
		libjsoncpp.so:devel/jsoncpp \
		libmosquitto.so:net/mosquitto
BUILD_DEPENDS=	cereal>=1.2.2:devel/cereal

USES=		cmake compiler:c++11-lang cpe lua:53 minizip pkgconfig sqlite \
		ssl

# Do not extract python Includes
EXTRACT_AFTER_ARGS=	--exclude hardware/plugins/Include

CONFLICTS_INSTALL?=	domoticz-[234]*

OPTIONS_SUB=		YES
OPTIONS_DEFINE=		PRECOMP PYTHON SBOOST SSSL TELLDUS
OPTIONS_DEFAULT=	PRECOMP PYTHON
SBOOST_DESC=		Use static Boost instead of dynamic linking
SSSL_DESC=		Use static OpenSSL library instead of dynamic linking
PYTHON_DESC=		Enable support for Python Plugins
TELLDUS_DESC=		Enable support for Telldus
PRECOMP_DESC=		Enable usage of precompiled header to speed build time

.include <bsd.port.options.mk>

# This hack is to get rid of dependency of git while building
# the package.
DOMOTICZ_REL=	15724
DOMOTICZ_TS=	1702451376
USE_GITHUB=	yes
GH_ACCOUNT=	domoticz
GH_PROJECT=	domoticz
GH_TAGNAME=	df755fe39

USE_RC_SUBR=	domoticz

USERS=		domoticz
GROUPS=		domoticz

DCMAKE_INSTALL_PREFIX=	${PREFIX}/domoticz
CMAKE_OFF+=		GIT_SUBMODULE USE_BUILTIN_JSONCPP USE_BUILTIN_MINIZIP \
			USE_BUILTIN_MQTT USE_BUILTIN_SQLITE USE_LUA_STATIC

.if ${PORT_OPTIONS:MSSSL}
CMAKE_ON+=	USE_OPENSSL_STATIC
.else
CMAKE_OFF+=	USE_OPENSSL_STATIC
.endif

.if ${PORT_OPTIONS:MSBOOST}
CMAKE_ON+=	USE_STATIC_BOOST
BUILD_DEPENDS+=	boost-libs>=0:devel/boost-libs
.else
CMAKE_OFF+=	USE_STATIC_BOOST
LIB_DEPENDS+=	libboost_system.so:devel/boost-libs
.endif

.if ${PORT_OPTIONS:MPYTHON}
CMAKE_ON+=	USE_PYTHON
USES+=		python:3.8+
.else
CMAKE_OFF+=	USE_PYTHON
.endif

.if ${PORT_OPTIONS:MTELLDUS}
LIB_DEPENDS+=	libtelldus-core.so:comms/telldus-core
.endif

.if ${PORT_OPTIONS:MPRECOMP}
CMAKE_ON+=	USE_PRECOMPILED_HEADER
.else
CMAKE_OFF+=	USE_PRECOMPILED_HEADER
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
