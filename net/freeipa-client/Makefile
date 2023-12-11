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

LIB_DEPENDS=	libcmocka.so:sysutils/cmocka \
		libcurl.so:ftp/curl \
		libini_config.so:devel/ding-libs \
		libjansson.so:devel/jansson \
		libnspr4.so:devel/nspr \
		libnss3.so:security/nss \
		libpopt.so:devel/popt \
		libpwquality.so:security/libpwquality \
		libsasl2.so:security/cyrus-sasl2 \
		libxmlrpc.so:net/xmlrpc-c

USES=		autoreconf gettext gmake gssapi:mit ldap libtool \
		localbase:ldflags pkgconfig python

GNU_CONFIGURE=	YES
CONFIGURE_ARGS=	--disable-dependency-tracking \
		--disable-server \
		--with-ipaplatform=freebsd \
		--without-ipatests \
		--without-server

# Remove all systemd dependant things
EXTRACT_AFTER_ARGS=	--exclude client/systemd --exclude daemons/dnssec \
			--exclude daemons/ipa-otpd --exclude \
			daemons/ipa-slapi-plugins --exclude init/systemd \
			--exclude init/tmpfilesd

# Remove Python bytecode files
post-install:
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/install/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/plugins/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/remote_plugins/2_49/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/remote_plugins/2_114/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/remote_plugins/2_156/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/remote_plugins/2_164/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaclient/remote_plugins/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipalib/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipalib/install/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/base/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/debian/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/fedora/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/fedora_container/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/freebsd/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/nixos/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/redhat/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/rhel/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/rhel_container/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipaplatform/suse/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipapython/__pycache__
	@${RM} -r ${STAGEDIR}${PYTHON_SITELIBDIR}/ipapython/install/__pycache__

.include <bsd.port.mk>
