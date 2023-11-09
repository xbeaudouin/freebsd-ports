PORTNAME=	freeipa-client
DISTVERSION=	4.11.0
CATEGORIES=	net
MASTER_SITES=	https://releases.pagure.org/freeipa/
DISTNAME=	freeipa-${DISTVERSION}

MAINTAINER=	xavier.beaudouin@klarasystems.com
COMMENT=	FreeIPA Client tools
WWW=		https://www.freeipa.org/

LICENSE=	GPLv3+
LICENSE_FILE_GPLv3+ =	${WRKSRC}/COPYING

BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}pip>0:devel/py-pip@${PY_FLAVOR}

LIB_DEPENDS=	libpopt.so:devel/popt \
		libjansson.so:devel/jansson \
		libnspr4.so:devel/nspr \
		libnss3.so:security/nss \
		libpwquality.so:security/libpwquality \
		libcmocka.so:sysutils/cmocka \
		libini_config.so:devel/ding-libs \
		libcurl.so:ftp/curl \
		libsasl2.so:security/cyrus-sasl2 \
		libxmlrpc.so:net/xmlrpc-c

USES=		autoreconf libtool gmake gettext python pkgconfig gssapi:mit \
		ldap localbase:ldflags

GNU_CONFIGURE=	YES
CONFIGURE_ARGS+=	--prefix=${PREFIX} --disable-server \
			--with-ipaplatform=freebsd \
			--disable-dependency-tracking \
			--without-ipatests --without-server

post-patch:
	@${RM} -rf ${WRKSRC}/client/systemd
	@${RM} -rf ${WRKSRC}/daemons/dnssec
	@${RM} -rf ${WRKSRC}/daemons/ipa-otpd
	@${RM} -rf ${WRKSRC}/daemons/ipa-slapi-plugins
	@${RM} -rf ${WRKSRC}/init/systemd
	@${RM} -rf ${WRKSRC}/init/tmpfilesd

.include <bsd.port.mk>
