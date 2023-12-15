PORTNAME=	home-assistant-frontend
PORTVERSION=	20230608.0
CATEGORIES=	www python
MASTER_SITES=	CHEESESHOPWHL
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
PKGNAMESUFFIX=	-devel
EXTRACT_SUFX=	-py3-none-any.whl
DISTNAME=	${PORTNAME:C/[^A-Za-z0-9.]+/_/g}-${PORTVERSION}

# Some staff from: https://github.com/freebsd/pytoport/issues/7
SUBDIRS_CHEESESHOPWHL=	py3/${PORTNAME:C/(.).*/\1/}/${PORTNAME:S/-${DISTVERSIONFULL}$//}
MASTER_SITE_CHEESESHOPWHL+= \
	https://files.pythonhosted.org/packages/${SUBDIRS_CHEESESHOPWHL}/ \
	https://pypi.org/packages/${SUBDIRS_CHEESESHOPWHL}/
MASTER_SITES_SUBDIRS+=	CHEESESHOPWHL:py3/${PORTNAME:C/(.).*/\1/}/${PORTNAME:S/-${DISTVERSIONFULL}$//}

MAINTAINER=	kiwi@oav.net
COMMENT=	The Home Assistant frontend
WWW=		https://www.home-assistant.io/

LICENSE=	APACHE20
ICENSE_FILE=	${WRKDIR}/${DISTNAME}.dist-info/LICENSE.md

USES=		python:3.10
USE_PYTHON=	flavors

NO_ARCH=	yes
NO_BUILD=	yes

# This is to prevent Mk/Uses/python.mk do-configure target from firing.
do-configure:
	@${ECHO} 'No configure'

do-install:
	${MKDIR} ${STAGEDIR}/${PYTHON_SITELIBDIR}/hass_frontend
	cd ${WRKDIR}/hass_frontend && ${COPYTREE_SHARE} . ${STAGEDIR}/${PYTHON_SITELIBDIR}/hass_frontend
	${MKDIR} ${STAGEDIR}/${PYTHON_SITELIBDIR}/${DISTNAME}.dist-info
	cd ${WRKDIR}/${DISTNAME}.dist-info && ${COPYTREE_SHARE} . ${STAGEDIR}/${PYTHON_SITELIBDIR}/${DISTNAME}.dist-info

post-stage:
	# Generate plist.
	@${SETENV} ${CO_ENV} ${SH} ${SCRIPTSDIR}/check-stagedir.sh makeplist | \
		${GREP} -v ^\/ | \
		${SED} -e 's|%%PYTHON_SITELIBDIR%%|${PYTHONPREFIX_SITELIBDIR}|' \
			-e 's|%%PYTHON_EXT_SUFFIX%%|${PYTHON_EXT_SUFFIX}|' \
			> ${TMPPLIST}

.include <bsd.port.mk>
