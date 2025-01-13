PORTNAME=	homeassistant
PORTVERSION=	2024.1.3
CATEGORIES=	www python
PORTREVISION=	1
MASTER_SITES=	# nothing to extract
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
DISTFILES=	# nothing to extract
EXTRACT_ONLY=	# nothing to extract

MAINTAINER=	rozhuk.im@gmail.com
COMMENT=	Open-source home automation platform running on Python
WWW=		https://www.home-assistant.io/

LICENSE=	APACHE20

# Real run deps.
RUN_DEPENDS=	ffmpeg:multimedia/ffmpeg \
		${PYTHON_PKGNAMEPREFIX}sqlite3>=0:databases/py-sqlite3@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pip>=0:devel/py-pip@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}zlib-ng>=0.4:archivers/py-zlib-ng@${PY_FLAVOR} 
# VENV bootstrap deps.
RUN_DEPENDS+=	cmake:devel/cmake-core \
		ninja:devel/ninja \
		pkg-config:devel/pkgconf \
		rustc:lang/rust

USES=		python:3.11
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

post-stage:
	@${ECHO_CMD} "@dir(homeassistant,homeassistant,) /var/db/homeassistant" >> ${TMPPLIST}
	# Generate plist.
	@${SETENV} ${CO_ENV} ${SH} ${SCRIPTSDIR}/check-stagedir.sh makeplist | \
		${GREP} -v ^\/ | \
		${SED} -e 's|%%PYTHON_SITELIBDIR%%|${PYTHONPREFIX_SITELIBDIR}|' \
			-e 's|%%PYTHON_EXT_SUFFIX%%|${PYTHON_EXT_SUFFIX}|' \
			> ${TMPPLIST}

.include <bsd.port.mk>
