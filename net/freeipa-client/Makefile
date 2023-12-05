PORTNAME=	freeipa-client
DISTVERSION=	4.11.0
CATEGORIES=	net
MASTER_SITES=	https://releases.pagure.org/freeipa/
DISTNAME=	freeipa-${DISTVERSION}

MAINTAINER=	xavier.beaudouin@klarasystems.com
COMMENT=	FreeIPA Client tools
WWW=		https://www.freeipa.org/

LICENSE=	GPLv3+
LICENSE_FILE=	${WRKSRC}/COPYING

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
CONFIGURE_ARGS+=	--disable-server \
			--with-ipaplatform=freebsd \
			--disable-dependency-tracking \
			--without-ipatests --without-server

EXTRACT_AFTER_ARGS=	--exclude client/systemd \
			--exclude daemons/dnssec \
			--exclude daemons/ipa-otpd \
			--exclude daemons/ipa-slapi-plugins \
			--exclude init/systemd \
			--exclude init/tmpfilesd

.include <bsd.port.mk>
