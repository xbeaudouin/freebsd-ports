# $FreeBSD$

PORTNAME=	domoticz-devel
PORTVERSION=	3.${DOMOTICZ_REL}
CATEGORIES=	www

MAINTAINER=	kiwi@oav.net
COMMENT=	Home Automation System

LICENSE=	GPLv3

LIB_DEPENDS=	libcurl.so:ftp/curl \
		libexpat.so:textproc/expat2 \
		libtelldus-core.so:comms/telldus-core \
		libsysinfo.so:devel/libsysinfo

CONFLICTS_INSTALL?=	domoticz-[23]*

OPTIONS_SUB=	YES
OPTIONS_DEFINE=	SBOOST SLUA SMQTT SSQLITE
SBOOST_DESC=	Use static Boost instead of dynamic linking
SLUA_DESC=	Use domoticz provided LUA instead of ports one
SMQTT_DESC=	Use domoticz mosquitto instead of ports one
SSQLITE_DESC=	Use domoticz SQLLite instead of ports one

.include <bsd.port.options.mk>

# This hack is to get rid of dependency of git while building
# the package.
DOMOTICZ_REL=	5187
DOMOTICZ_TS=	1464510250
USE_GITHUB=	yes
GH_ACCOUNT=	domoticz OpenZWave:ozw
GH_PROJECT=	domoticz open-zwave:ozw
GH_TAGNAME=	1660d9a 9b7c45a:ozw

USES=		gmake cmake iconv pkgconfig execinfo python

USE_RC_SUBR=	domoticz

USERS=		domoticz
GROUPS=		domoticz

CMAKE_ARGS+=	-DUSE_STATIC_OPENZWAVE="YES" \
		-DUSE_BUILTIN_ZLIB="NO" \
		-DUSE_PYTHON="YES"

.if ${PORT_OPTIONS:MSBOOST}
CMAKE_ARGS+=	-DUSE_STATIC_BOOST="YES"
BUILD_DEPENDS+=	boost-libs>=0:devel/boost-libs \
		boost-python-libs>=0:devel/boost-python-libs
.else
CMAKE_ARGS+=	-DUSE_STATIC_BOOST="NO"
LIB_DEPENDS+=	libboost_system.so:devel/boost-libs \
		libboost_python.so:devel/boost-python-libs
.endif

.if ${PORT_OPTIONS:MSLUA}
CMAKE_ARGS+=	-DUSE_BUILTIN_LUA="YES"
.else
CMAKE_ARGS+=	-DUSE_BUILTIN_LUA="NO"
USES+=		lua:52
.endif

.if ${PORT_OPTIONS:MSMQTT}
CMAKE_ARGS+=	-DUSE_BUILTIN_MQTT="YES"
.else
CMAKE_ARGS+=	-DUSE_BUILTIN_MQTT="NO"
LIB_DEPENDS+=	libmosquitto.so:net/mosquitto
.endif

.if ${PORT_OPTIONS:MSSQLITE}
CMAKE_ARGS+= 	-DUSE_BUILTIN_SQLITE="YES"
.else
CMAKE_ARGS+= 	-DUSE_BUILTIN_SQLITE="NO"
USES+=		sqlite
.endif

post-extract:
	@${LN} -s ${WRKSRC_ozw} ${WRKSRC}/../open-zwave-read-only

post-patch:
	@${REINPLACE_CMD} -e "s,\/opt,${PREFIX},g" ${WRKSRC}/CMakeLists.txt
	@${REINPLACE_CMD} -e "s,XXXPREFIXXXX,${PREFIX}/domoticz,g" ${WRKSRC}/CMakeLists.txt
	@${REINPLACE_CMD} -e "s,XXXDOMOTICZXXX,${DOMOTICZ_REL},g" ${WRKSRC}/appversion.default
	@${REINPLACE_CMD} -e "s,XXXHASHXXX,${GH_TAGNAME},g" ${WRKSRC}/appversion.default
	@${REINPLACE_CMD} -e "s,XXXTIMEXXX,${DOMOTICZ_TS},g" ${WRKSRC}/appversion.default
	@${REINPLACE_CMD} -e "/^ADD_PRECOMPILED_HEADER/ d" ${WRKSRC}/CMakeLists.txt

pre-build:
	#cd ${WRKSRC_ozw} && ${DO_MAKE_BUILD}
	cd ${WRKSRC_ozw} && ${GMAKE}

post-install:
	${MKDIR} ${STAGEDIR}/var/db/domoticz ${STAGEDIR}/var/run/domoticz

.include <bsd.port.mk>
