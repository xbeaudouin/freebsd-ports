PORTNAME=	home-assistant-bluetooth
PORTVERSION=	1.4.0
CATEGORIES=	devel python
MASTER_SITES=	CHEESESHOP
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	rozhuk.im@gmail.com
COMMENT=	Home Assistant Bluetooth Models and Helpers

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE

# bleak does not support FreeBSD bluetooth stack, not ported yet.
#RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}bleak>=0.16.0:comms/py-bleak@${PY_FLAVOR}

USES=		python:3.9+
USE_PYTHON=	autoplist distutils flavors

.include <bsd.port.mk>
