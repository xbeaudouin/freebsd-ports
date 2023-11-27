PORTNAME=	homeassistant
PORTVERSION=	2023.11.3
CATEGORIES=	www python
MASTER_SITES=	CHEESESHOP
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	kiwi@oav.net
COMMENT=	Opensource Home Automation system.

LICENSE=	APACHE20

RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}astral:astro/py-astral@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}attrs:devel/py-attrs@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}atomicwrites-homeassistant:devel/py-atomicwrites-homeassistant@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}awesomeversion:devel/py-awesomeversion@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}bcrypt:security/py-bcrypt@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}certifi>=2021.5.30:security/py-certifi@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}ciso8601:devel/py-ciso8601@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}httpx:www/py-httpx@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}home-assistant-blue-tooth:comms/py-home-assistant-bluetooth@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}ifaddr:net/py-ifaddr@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}Jinja2:devel/py-Jinja2@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}lru-dict:devel/py-lru-dict@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pyjwt=2.8.0:www/py-pyjwt@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}cryptography:security/py-cryptography@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}openssl:security/py-openssl@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}orjson:devel/py-orjson@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}packaging:devel/py-packaging@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pip:devel/py-pip@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}python-slugify:textproc/py-python-slugify@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}yaml:devel/py-yaml@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}requests:www/py-requests@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}requests:www/py-requests@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}typing-extensions:www/py-requests@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}ulid-transform:devel/py-ulid-transform@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}voluptuous:devel/py-voluptuous@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}voluptuous-serialize:devel/py-voluptuous-serialize@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}yarl:www/py-yarl@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}aiohttp:www/py-aiohttp@${PY_FLAVOR}

USES=		python
USE_PYTHON=	distutils autoplist

NO_ARCH=	yes

DOCSDIR=	${PREFIX}/share/doc/${PKGNAMEPREFIX}${PORTNAME}
PORTDOCS=	*

.include <bsd.port.mk>
