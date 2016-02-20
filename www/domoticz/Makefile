# $FreeBSD$

PORTNAME=	domoticz
PORTVERSION=	2.${DOMOTICZ_REL}
CATEGORIES=	www

MAINTAINER=	kiwi@oav.net
COMMENT=	Home Automation System

LICENSE=	GPLv3

LIB_DEPENDS=	libcurl.so:${PORTSDIR}/ftp/curl \
		libexpat.so:${PORTSDIR}/textproc/expat2 \
		libboost_system.so:${PORTSDIR}/devel/boost-libs \
		libboost_python.so:${PORTSDIR}/devel/boost-python-libs \
		libtelldus-core.so:${PORTSDIR}/comms/telldus-core \
		libmosquitto.so:${PORTSDIR}/net/mosquitto \
		libopenzwave.so:${PORTSDIR}/comms/openzwave

# This hack is to get rid of dependency of git while building
# the package.
DOMOTICZ_REL=	4671
DOMOTICZ_TS=	1455960354
USE_GITHUB=	yes
GH_TAGNAME=	040230a

USES=		cmake iconv pkgconfig lua:52 execinfo sqlite python

USE_RC_SUBR=	domoticz

USERS=		domoticz
GROUPS=		domoticz

CMAKE_ARGS+= 	-DUSE_BUILTIN_SQLITE="NO" \
		-DUSE_BUILTIN_LUA="NO" \
		-DUSE_STATIC_BOOST="NO" \
		-DUSE_BUILTIN_ZLIB="NO" \
		-DUSE_STATIC_OPENZWAVE="NO" \
		-DUSE_PYTHON="YES" \
		-DUSE_BUILTIN_MQTT="NO"

post-patch:
	@${REINPLACE_CMD} -e "s,\/opt,${PREFIX},g" ${WRKSRC}/CMakeLists.txt
	@${REINPLACE_CMD} -e "s,XXXPREFIXXXX,${PREFIX}/domoticz,g" ${WRKSRC}/CMakeLists.txt
	@${REINPLACE_CMD} -e "s,XXXDOMOTICZXXX,${DOMOTICZ_REL},g" ${WRKSRC}/appversion.default
	@${REINPLACE_CMD} -e "s,XXXHASHXXX,${GH_TAGNAME},g" ${WRKSRC}/appversion.default
	@${REINPLACE_CMD} -e "s,XXXTIMEXXX,${DOMOTICZ_TS},g" ${WRKSRC}/appversion.default
	@${REINPLACE_CMD} -e "/^ADD_PRECOMPILED_HEADER/ d" ${WRKSRC}/CMakeLists.txt

post-install:
	${MKDIR} ${STAGEDIR}/var/db/domoticz ${STAGEDIR}/var/run/domoticz

.include <bsd.port.mk>
