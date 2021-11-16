PORTNAME=	envoy_reader
PORTVERSION=	0.20.0
CATEGORIES=	comms python
MASTER_SITES=	CHEESESHOP
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	kiwi@oav.net
COMMENT=	Enphase Envoy reader on the local network

LICENSE=	GPLv3

RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}httpx=1.12.1:www/py-httpx@${PY_FLAVOR}\
		${PYTHON_PKGNAMEPREFIX}envoy_utils=0.0.1:comms/py-envoy_utils@${PY_FLAVOR}

USES=		python
USE_PYTHON=	distutils autoplist

NO_ARCH=	yes

DOCSDIR=	${PREFIX}/share/doc/${PKGNAMEPREFIX}${PORTNAME}
PORTDOCS=	*

.include <bsd.port.mk>
