PORTNAME=	netifaces-plus
PORTVERSION=	0.12.2
CATEGORIES=	net python
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	kiwi@oav.net	
COMMENT=	Getting network addresses from Python 3
WWW=		https://pypi.org/project/netifaces-plus/

LICENSE=	MIT

USES=		python
USE_GITHUB=	yes
USE_PYTHON=	allflavors autoplist distutils cython

GH_ACCOUNT=	tsukumijima
GH_PROJECT=     ${PORTNAME}
GH_TAGNAME=     742dd07

post-install:
	${STRIP_CMD} ${STAGEDIR}${PYTHONPREFIX_SITELIBDIR}/_netifaces*.so

do-test:
	@cd ${WRKSRC} && ${SETENV} ${TEST_ENV} ${PYTHON_CMD} test.py

.include <bsd.port.mk>
