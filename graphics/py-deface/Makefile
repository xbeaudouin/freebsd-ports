PORTNAME=	deface
PORTVERSION=	1.5.0
CATEGORIES=	graphics python
MASTER_SITES=	PYPI
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}

MAINTAINER=	kiwi@FreeBSD.org
COMMENT=	Video anonymization by face detection
WWW=		https://github.com/ORB-HD/deface

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

# opencv-python-headless fournit le même module cv2 qu'attend deface,
# sans dépendances GUI (pas de GTK/Qt). C'est le port à utiliser
# plutôt que graphics/py-opencv (le vieux slave port basé sur
# graphics/opencv système, qui est déprécié depuis 2021).
#
# Remplacer par graphics/py-opencv@${PY_FLAVOR} si py-opencv-python-headless
# n'est pas disponible dans votre arbre de ports, mais attention aux
# conflits de namespace cv2 si graphics/opencv est déjà installé.

BUILD_DEPENDS=	${PYTHON_PKGNAMEPREFIX}setuptools>=42:devel/py-setuptools@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}setuptools-scm>=6:devel/py-setuptools-scm@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}wheel>=0:devel/py-wheel@${PY_FLAVOR}

# ffmpeg est requis à l'exécution pour imageio-ffmpeg
LIB_DEPENDS=	libavcodec.so:multimedia/ffmpeg

RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}imageio>=2.25:graphics/py-imageio@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}imageio-ffmpeg>=0.4.6:graphics/py-imageio-ffmpeg@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}numpy>=0:math/py-numpy@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}tqdm>=0:misc/py-tqdm@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}scikit-image>=0:graphics/py-scikit-image@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}opencv-python-headless>=4:graphics/py-opencv-python-headless@${PY_FLAVOR}

# Dépendance optionnelle : accélération ONNX Runtime (CPU ou GPU).
# Non disponible comme wheel PyPI sur FreeBSD ; utiliser le port
# misc/onnxruntime si disponible dans votre arbre de ports.
# Sans cette dépendance, deface utilise le backend OpenCV (fonctionnel).
#
# Pour activer : décommenter les lignes ci-dessous et ajuster le port.
#OPTIONS_DEFINE=	ONNX
#OPTIONS_DEFAULT=
#ONNX_DESC=		Activer le backend ONNX Runtime (accélération CPU/GPU)
#ONNX_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}onnx>=0:misc/py-onnx@${PY_FLAVOR}

USES=		python:3.11+
USE_PYTHON=	autoplist pep517

# La variable SETUPTOOLS_SCM_PRETEND_VERSION évite l'erreur "git not found"
# lors du build hors d'un dépôt git (cas typique des ports)
MAKE_ENV=	SETUPTOOLS_SCM_PRETEND_VERSION=${PORTVERSION}

.include <bsd.port.mk>
