PORTNAME=	homeassistant
PORTVERSION=	2024.12.1
CATEGORIES=	www python
MASTER_SITES=	# nothing to extract
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
DISTFILES=	# nothing to extract
EXTRACT_ONLY=	# nothing to extract

MAINTAINER=	rozhuk.im@gmail.com
COMMENT=	Open-source home automation platform running on Python
WWW=		https://www.home-assistant.io/

LICENSE=	APACHE20

# Actual run dependencies of HA
RUN_DEPENDS=	ffmpeg:multimedia/ffmpeg \
		${PYTHON_PKGNAMEPREFIX}sqlite3>=0:databases/py-sqlite3@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pip>=0:devel/py-pip@${PY_FLAVOR}
# Run dependencies required by the dependencies installed during the
# bootstrap step in a Python virtual environment (venv)
RUN_DEPENDS+=	cmake:devel/cmake-core \
		gmake:devel/gmake \
		ninja:devel/ninja \
		rustc:lang/rust \
		${PYTHON_PKGNAMEPREFIX}uv-build>0:devel/py-uv-build@${PY_FLAVOR}
		git:devel/git
LIB_DEPENDS+=	libturbojpeg.so:graphics/libjpeg-turbo

# This version of HA runs only on python 3.13
USES=		python:3.13+ pkgconfig:run
USE_RC_SUBR=	home-assistant

NO_ARCH=	yes
NO_BUILD=	yes

SUB_LIST=	PORTVERSION=${PORTVERSION} \
		PYTHON_CMD=${PYTHON_CMD} \
		PYTHON_VERSION=${PYTHON_VERSION}

NO_WRKSUBDIR=	yes

#USERS=		homeassistant
USERS=		www
#GROUPS=		homeassistant
GROUPS=		www

OPTIONS_GROUP=	DB
OPTIONS_GROUP_DB=	MSSQL MYSQL PYMYSQL PGSQL

MYSQL_DESC=	MySQL/MariaDB support
PYMYSQL_DESC=	MySQL/MariaDB support via pymysql

MSSQL_SUB_LIST=		MSSQLCLIENT=pymssql
MSSQL_SUB_LIST_OFF=	MSSQLCLIENT=""
MYSQL_SUB_LIST=		MYSQLCLIENT=mysqlclient
MYSQL_SUB_LIST_OFF=	MYSQLCLIENT=""
PGSQL_SUB_LIST=		PGSQLCLIENT=psycopg2
PGSQL_SUB_LIST_OFF=	PGSQLCLIENT=""
PYMYSQL_SUB_LIST=	PYMYSQLCLIENT=pymysql
PYMYSQL_SUB_LIST_OFF=	PYMYSQLCLIENT=""

do-install:
	@${MKDIR} ${STAGEDIR}/var/db/homeassistant

.include <bsd.port.mk>
