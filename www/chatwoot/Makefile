PORTNAME=	chatwoot
PORTVERSION=	4.12.1
DISTVERSIONPREFIX=	v
CATEGORIES=	www
MAINTAINER=	kiwi@FreeBSD.org
COMMENT=	Open-source omni-channel customer support platform
WWW=		https://www.chatwoot.com/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

# --- Build dependencies ---
BUILD_DEPENDS=	rubygem-bundler>=2.4:devel/rubygem-bundler \
		node>=20:www/node20 \
		yarn:www/yarn

# --- Runtime dependencies ---
RUN_DEPENDS=	rubygem-bundler>=2.4:devel/rubygem-bundler \
		redis>=6.2:databases/redis

# --- PostgreSQL dependency (required) ---
USE_PGSQL=	yes
PGSQL_VER?=	15

USES=		ruby pgsql shebangfix

USE_GITHUB=	yes
GH_ACCOUNT=	chatwoot
GH_PROJECT=	chatwoot
GH_TAGNAME=	v${PORTVERSION}

# Chatwoot is a pure Ruby/JS web application, no compiled arch-specific code
NO_ARCH=	yes

# System user/group for the service
USERS?=		www
GROUPS?=	www

# rc.d service scripts (web server + Sidekiq background worker)
USE_RC_SUBR=	chatwoot chatwoot_worker

# Installation directories
CHATWOOT_DIR=		${PREFIX}/www/chatwoot
CHATWOOT_LOGDIR=	/var/log/chatwoot
CHATWOOT_RUNDIR=	/var/run/chatwoot
CHATWOOT_DBDIR=		/var/db/chatwoot

# Fix Ruby shebangs in bin/ scripts
SHEBANG_FILES=		bin/rails bin/rake bin/bundle bin/setup bin/update

SUB_FILES=		pkg-message
SUB_LIST+=		CHATWOOT_DIR=${CHATWOOT_DIR} \
			CHATWOOT_LOGDIR=${CHATWOOT_LOGDIR} \
			CHATWOOT_RUNDIR=${CHATWOOT_RUNDIR} \
			CHATWOOT_DBDIR=${CHATWOOT_DBDIR}

OPTIONS_DEFINE=		DOCS IMAGEMAGICK
OPTIONS_DEFAULT=	IMAGEMAGICK
IMAGEMAGICK_DESC=	Enable image processing via ImageMagick

IMAGEMAGICK_BUILD_DEPENDS=	convert:graphics/ImageMagick7
IMAGEMAGICK_RUN_DEPENDS=	convert:graphics/ImageMagick7

# Bundler environment used across build targets
BUNDLE_ENV=	HOME=${WRKDIR} \
		BUNDLE_PATH=${WRKSRC}/vendor/bundle \
		BUNDLE_BIN=${WRKSRC}/vendor/bundle/bin \
		GEM_HOME=${WRKSRC}/vendor/bundle \
		RAILS_ENV=production

NODE_ENV=	production

post-extract:
	# Copy the example environment file so the build has a base .env
	@${CP} ${WRKSRC}/.env.example ${WRKSRC}/.env

pre-build:
	# Patch Gemfile to remove platform-specific Linux gems if necessary
	@${REINPLACE_CMD} -e 's/gem "mini_racer"/# gem "mini_racer" # disabled on FreeBSD/' \
		${WRKSRC}/Gemfile
	# Use the system-compatible JS runtime (execjs + node)
	@${REINPLACE_CMD} -e 's/gem "execjs"/gem "execjs" # uses node via PATH/' \
		${WRKSRC}/Gemfile || true

do-build:
	# --- Install Ruby gems via Bundler (deployment mode, frozen) ---
	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
		${BUNDLE} config set --local deployment true
	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
		${BUNDLE} config set --local without 'development test'
	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
		${BUNDLE} install --jobs ${MAKE_JOBS_NUMBER}

	# --- Install JS dependencies via Yarn ---
	cd ${WRKSRC} && ${SETENV} HOME=${WRKDIR} NODE_ENV=${NODE_ENV} \
		yarn install --frozen-lockfile --production=false

	# --- Pre-compile frontend assets ---
	# SECRET_KEY_BASE is a dummy value only used at asset compile time
	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
		SECRET_KEY_BASE=freebsd_build_placeholder \
		POSTGRES_HOST=/tmp \
		${BUNDLE} exec rails assets:precompile

do-install:
	# --- Create directories ---
	${MKDIR} ${STAGEDIR}${CHATWOOT_DIR}
	${MKDIR} ${STAGEDIR}${CHATWOOT_LOGDIR}
	${MKDIR} ${STAGEDIR}${CHATWOOT_RUNDIR}
	${MKDIR} ${STAGEDIR}${CHATWOOT_DBDIR}/storage

	# --- Copy application files ---
	cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}${CHATWOOT_DIR} \
		"! -path './.git*' \
		 ! -path './node_modules*' \
		 ! -path './spec*' \
		 ! -path './test*' \
		 ! -path './.github*'"

	# --- Install environment config sample ---
	${INSTALL_DATA} ${WRKSRC}/.env.example \
		${STAGEDIR}${CHATWOOT_DIR}/.env.sample

	# --- Fix permissions on writable directories ---
	${CHOWN} -R ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_DIR}
	${CHMOD} 750 ${STAGEDIR}${CHATWOOT_DIR}
	${CHOWN} ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_LOGDIR}
	${CHOWN} ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_RUNDIR}
	${CHOWN} ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_DBDIR}

post-install:
	# Create a convenience symlink for the rails binary
	${LN} -sf ${CHATWOOT_DIR}/bin/rails ${STAGEDIR}${PREFIX}/bin/chatwoot-rails
	${LN} -sf ${CHATWOOT_DIR}/bin/rake  ${STAGEDIR}${PREFIX}/bin/chatwoot-rake

.include <bsd.port.mk>
