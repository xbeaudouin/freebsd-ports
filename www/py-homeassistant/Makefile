PORTNAME=	homeassistant
PORTVERSION=	2023.11.3
CATEGORIES=	www python
MASTER_SITES=	CHEESESHOPWHL
PKGNAMEPREFIX=	${PYTHON_PKGNAMEPREFIX}
EXTRACT_SUFX=	-py3-none-any.whl
DISTNAME=	${PORTNAME:C/[^A-Za-z0-9.]+/_/g}-${PORTVERSION}

# Some staff from: https://github.com/freebsd/pytoport/issues/7
SUBDIRS_CHEESESHOPWHL=	py3/${PORTNAME:C/(.).*/\1/}/${PORTNAME:S/-${DISTVERSIONFULL}$//}
MASTER_SITE_CHEESESHOPWHL+= \
	https://files.pythonhosted.org/packages/${SUBDIRS_CHEESESHOPWHL}/ \
	https://pypi.org/packages/${SUBDIRS_CHEESESHOPWHL}/
MASTER_SITES_SUBDIRS+=	CHEESESHOPWHL:py3/${PORTNAME:C/(.).*/\1/}/${PORTNAME:S/-${DISTVERSIONFULL}$//}

MAINTAINER=	kiwi@oav.net
COMMENT=	Opensource Home Automation system.

LICENSE=	APACHE20

RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}astral>=2.2:astro/py-astral@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}attrs>=21.2.0:devel/py-attrs@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}atomicwrites-homeassistant>=1.4.0:devel/py-atomicwrites-homeassistant@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}awesomeversion>=22.1.0:devel/py-awesomeversion@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}bcrypt>=3.1.7:security/py-bcrypt@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}certifi>=2021.5.30:security/py-certifi@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}ciso8601>=2.2.0:devel/py-ciso8601@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}httpx>=0.23.0:www/py-httpx@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}home-assistant-bluetooth>=1.3.0:comms/py-home-assistant-bluetooth@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}ifaddr>=0.1.7:net/py-ifaddr@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}Jinja2>=3.0.1:devel/py-Jinja2@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}lru-dict>=1.1.8:devel/py-lru-dict@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pyjwt>=2.8.0:www/py-pyjwt@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}cryptography>=38.0.1:security/py-cryptography@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}openssl>=23.2.0:security/py-openssl@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}orjson>=3.8.0:devel/py-orjson@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}packaging>=23.2:devel/py-packaging@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}pip>=22.2.2:devel/py-pip@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}python-slugify>=8.0.1:textproc/py-python-slugify@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}yaml>=5.4.1:devel/py-yaml@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}requests>=2.31.0:www/py-requests@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}typing-extensions>=3.10.0:www/py-typing-extensions@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}ulid-transform>=0.9.0:devel/py-ulid-transform@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}voluptuous>=0.13.1:devel/py-voluptuous@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}voluptuous-serialize>=2.5.0:devel/py-voluptuous-serialize@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}yarl>=1.8.1:www/py-yarl@${PY_FLAVOR} \
		${PYTHON_PKGNAMEPREFIX}aiohttp>=3.8.1:www/py-aiohttp@${PY_FLAVOR} \


USES=		python:3.9+
USE_PYTHON=	distutils autoplist
WRKSRC=		${WRKDIR}/${PORTNAME}

#USERS=		homeassistant
#GROUPS=		homeassistant
USERS=		www
GROUPS=		www

SUB_LIST=	PYTHON_CMD=${PYTHON_CMD} \
		PYTHON_VERSION=${PYTHON_VERSION}

NO_ARCH=	yes
NO_BUILD=	yes

OPTIONS_GROUP=	DB
OPTIONS_GROUP_DB=	MSSQL MYSQL PYMYSQL PGSQL

MSSQL_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}pymssql>=0:databases/py-pymssql@${PY_FLAVOR}
MYSQL_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}mysqlclient>=0:databases/py-mysqlclient@${PY_FLAVOR}
PYMYSQL_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}pymysql>=0:databases/py-pymysql@${PY_FLAVOR}
PGSQL_RUN_DEPENDS=	${PYTHON_PKGNAMEPREFIX}psycopg2>=2.7:databases/py-psycopg2@${PY_FLAVOR}

MYSQL_DESC=	MySQL/MariaDB support
PYMYSQL_DESC=	MySQL/MariaDB support via pymysql

post-patch:
	# Enable FreeBSD support.
	@${REINPLACE_CMD} -e 's|"darwin", "linux"|"darwin", "linux", "freebsd"|g' \
		${WRKSRC}/__main__.py
#	# Extra patch.
#.for __RUN_DEPEND in ${RUN_DEPENDS}
#	@${ECHO} -n "${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}: "
#	@${GREP} -E "^${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}(>|<|==|>=|<=)" \
#	    ${WRKSRC}/package_constraints.txt | \
#		${SED} -E "s/${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}(>|<|==|>=|<=)([.0-9]*)/\2/g" | \
#		    ${TR} -cd '[:print:]'
#	@${ECHO} " -> ${__RUN_DEPEND:C/.*(>|<|==|>=|<=)(.*)[:].*/\2/}"
#
#	@${REINPLACE_CMD} -E \
#		-e "s/(^|\")${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}(>|<|==|>=|<=)[.0-9]*/\1${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}>=${__RUN_DEPEND:C/.*(>|<|==|>=|<=)(.*)[:].*/\2/}/g" \
#		${WRKDIR}/${DISTNAME}.dist-info/METADATA \
#		${WRKSRC}/package_constraints.txt \
#		${WRKSRC}/components/*/manifest.json
#.endfor
# Port name did not match python packet name.
#  PyNaCl sqlalchemy
#.for __RUN_DEPEND in jinja2 PyJWT pyyaml
#	@${ECHO} -n "${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}: "
#	@${GREP} -E "^${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}(>|<|==|>=|<=)" \
#	    ${WRKSRC}/package_constraints.txt | \
#		${SED} -E "s/${__RUN_DEPEND:C/(.*)(>|<|==|>=|<=).*/\1/}(>|<|==|>=|<=)([.0-9]*)/\2/g" | \
#		    ${TR} -cd '[:print:]'
#	@${ECHO} " -> ${__RUN_DEPEND:C/.*(>|<|==|>=|<=)(.*)[:].*/\2/} >=0"
#
#	@${REINPLACE_CMD} -E \
#		-e 's/(^|\")${__RUN_DEPEND}(>|<|==|>=|<=)[.0-9]*/\1${__RUN_DEPEND}>=0/g' \
#		${WRKDIR}/${DISTNAME}.dist-info/METADATA \
#		${WRKSRC}/package_constraints.txt \
#		${WRKSRC}/components/*/manifest.json
#.endfor
#	@${REINPLACE_CMD} -E "s/(^|\")pip(>|<|==|>=|<=)([.0-9]*),(>|<|==|>=|<=)([.0-9]*)/\1pip\2\3/" \
#		${WRKDIR}/${DISTNAME}.dist-info/METADATA \
#		${WRKSRC}/package_constraints.txt
	@${FIND} ${WRKDIR} -name '*.bak' -name '*.orig' -delete

# This is to prevent Mk/Uses/python.mk do-configure target from firing.
do-configure:
	@${ECHO} 'No configure'

do-install:
	${MKDIR} ${STAGEDIR}/${PYTHON_SITELIBDIR}/${PORTNAME}
	cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}/${PYTHON_SITELIBDIR}/${PORTNAME}
	${MKDIR} ${STAGEDIR}/${PYTHON_SITELIBDIR}/${DISTNAME}.dist-info
	cd ${WRKDIR}/${DISTNAME}.dist-info && ${COPYTREE_SHARE} . ${STAGEDIR}/${PYTHON_SITELIBDIR}/${DISTNAME}.dist-info

post-stage:
	@${MKDIR} ${STAGEDIR}/var/db/homeassistant
	@${ECHO_CMD} "@dir(homeassistant,homeassistant,) /var/db/homeassistant" >> ${TMPPLIST}
	# Generate plist.
	@${SETENV} ${CO_ENV} ${SH} ${SCRIPTSDIR}/check-stagedir.sh makeplist | \
		${GREP} -v ^\/ | \
		${SED} -e 's|%%PYTHON_SITELIBDIR%%|${PYTHONPREFIX_SITELIBDIR}|' \
			-e 's|%%PYTHON_EXT_SUFFIX%%|${PYTHON_EXT_SUFFIX}|' \
			> ${TMPPLIST}


.include <bsd.port.mk>
