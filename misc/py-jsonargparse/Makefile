PORTNAME=	jsonargparse
#PORTVERSION=	4.30.0
PORTVERSION=	3.19.4
CATEGORIES=	misc python
MASTER_SITES=	PYPI
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	kiwi@oav.net
COMMENT=	Library for creating CLIs
WWW=		https://github.com/omni-us/jsonargparse

LICENSE=	MIT

BUILD_DEPENDS=	${PY_SETUPTOOLS} \
		${PYTHON_PKGNAMEPREFIX}wheel>0:devel/py-wheel@${PY_FLAVOR}
RUN_DEPENDS=	{PYTHON_PKGNAMEPREFIX}pyyaml5>3.13:devel/py-pyyaml5@${PY_FLAVOR}

USES=		python
#USE_PYTHON=	allflavors distutils pep517 autoplist
USE_PYTHON=	allflavors pep517 autoplist

NO_ARCH=	yes

DOCSDIR=	${PREFIX}/share/doc/${PKGNAMEPREFIX}${PORTNAME}
PORTDOCS=	*

.include <bsd.port.mk>
