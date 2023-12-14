PORTNAME=	hass-nabucasa
PORTVERSION=	0.56.0
CATEGORIES=	devel python
MASTER_SITES=	CHEESESHOP
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	rozhuk.im@gmail.com
COMMENT=	Home Assistant cloud integration by Nabu Casa, Inc.

LICENSE=	GPLv3

RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}acme>=1.29.0:security/py-acme@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}aiohttp>=3.6.1:www/py-aiohttp@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}atomicwrites>=1.4.0:devel/py-atomicwrites@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}attrs>=19.3:devel/py-attrs@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}cryptography>=2.8:security/py-cryptography@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pycognito>=2022.3.0:devel/py-pycognito@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}snitun>=0.31.0:devel/py-snitun@${PY_FLAVOR}

USES=		python
USE_PYTHON=	autoplist distutils

post-patch:
	@${REINPLACE_CMD} -e 's|==|>=|g' \
		-e 's|atomicwrites-homeassistant|atomicwrites|g' \
		-e 's|2022.8.0|2022.3.0|g' \
		${WRKSRC}/setup.py

.include <bsd.port.mk>
