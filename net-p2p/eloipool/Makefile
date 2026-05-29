PORTNAME=	eloipool
DISTVERSION=	g20230101
#PORTREVISION=	0
CATEGORIES=	net-p2p

MAINTAINER=	ports@FreeBSD.org
COMMENT=	Fast Python3 Bitcoin pool server with merged mining support
WWW=		https://github.com/luke-jr/eloipool

#LICENSE=	AGPL30
#LICENSE_FILE=	${WRKSRC}/COPYING

# asynchat was removed in Python 3.12; constrain accordingly
USES=		python:3.6-3.11,run shebangfix
USE_GITHUB=	yes
GH_ACCOUNT=	luke-jr
GH_PROJECT=	eloipool
GH_TAGNAME=	d488480	# pin to a specific commit: git log --oneline -1

NO_BUILD=	yes
NO_ARCH=	yes

SHEBANG_FILES=	eloipool.py

RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}base58>=0:finance/py-base58 \
		${PYTHON_PKGNAMEPREFIX}python-bitcoinrpc>=0:net-p2p/py-python-bitcoinrpc

OPTIONS_DEFINE=		POSTGRESQL MYSQL DOCS EXAMPLES
OPTIONS_DEFAULT=

POSTGRESQL_DESC=	Share logging via PostgreSQL (psycopg2)
MYSQL_DESC=		Share logging via MySQL (PyMySQL)

POSTGRESQL_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}psycopg2>=2.0:databases/py-psycopg2
MYSQL_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}pymysql>=0:databases/py-pymysql

USERS=		eloipool
GROUPS=		eloipool

USE_RC_SUBR=	eloipool

DATADIR=	${PREFIX}/share/${PORTNAME}

SUB_FILES=	eloipool.sh
SUB_LIST=	PYTHON_CMD=${PYTHON_CMD} \
		DATADIR=${DATADIR}

do-install:
	# Install all Python source files to DATADIR
	${MKDIR} ${STAGEDIR}${DATADIR}
	(cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}${DATADIR} \
		"! -name '*.pyc' ! -name '.git' ! -name 'config.py'")

	# Install wrapper script
	${INSTALL_SCRIPT} ${WRKDIR}/eloipool.sh \
		${STAGEDIR}${PREFIX}/bin/eloipool

	# Install sample config
	${MKDIR} ${STAGEDIR}${PREFIX}/etc/eloipool
	${INSTALL_DATA} ${WRKSRC}/config.py.example \
		${STAGEDIR}${PREFIX}/etc/eloipool/config.py.sample

do-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/README \
		${STAGEDIR}${DOCSDIR}/

do-install-EXAMPLES-on:
	${MKDIR} ${STAGEDIR}${EXAMPLESDIR}
	${INSTALL_DATA} ${WRKSRC}/config.py.example \
		${STAGEDIR}${EXAMPLESDIR}/

.include <bsd.port.mk>
