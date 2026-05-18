PORTNAME=	chatwoot
PORTVERSION=	4.13.0
DISTVERSIONPREFIX=	v
CATEGORIES=	www
MAINTAINER=	kiwi@FreeBSD.org
COMMENT=	Open-source omni-channel customer support platform
WWW=		https://www.chatwoot.com/

LICENSE=	MIT
LICENSE_FILE=	${WRKSRC}/LICENSE

# --- Build dependencies ---
BUILD_DEPENDS=	rubygem-bundler>=2.4:sysutils/rubygem-bundler \
		yarn:www/yarn

# --- Runtime dependencies ---
RUN_DEPENDS=	rubygem-bundler>=2.4:sysutils/rubygem-bundler \
		redis>=6.2:databases/redis

# --- PostgreSQL dependency (required) ---
USE_PGSQL=	yes
PGSQL_VER?=	15

USES=		ruby pgsql shebangfix nodejs:env

# BUNDLE_CMD: use the system-installed binary directly.
# Do NOT use "ruby -S bundle":  ruby -S searches GEM_PATH for the script,
# and we must not override GEM_PATH before vendor/bundle is populated.
# Do NOT use "bundle config" as a separate step for the same reason.
BUNDLE_CMD=	${LOCALBASE}/bin/bundle

USE_GITHUB=	yes
GH_ACCOUNT=	chatwoot
GH_PROJECT=	chatwoot
GH_TAGNAME=	v${PORTVERSION}

NO_ARCH=	yes

USERS?=		www
GROUPS=		www

USE_RC_SUBR=	chatwoot chatwoot_worker

CHATWOOT_DIR=		${PREFIX}/www/chatwoot
CHATWOOT_LOGDIR=	/var/log/chatwoot
CHATWOOT_RUNDIR=	/var/run/chatwoot
CHATWOOT_DBDIR=		/var/db/chatwoot

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

# Only BUNDLE_PATH is exported — bundler derives GEM_HOME/GEM_PATH from it
# internally once gems are installed.  Overriding GEM_HOME/GEM_PATH here
# causes rubygems to search vendor/bundle (empty) for the bundler gem itself
# and abort with "can't find gem bundler (>= 0.a)".
BUNDLE_ENV=	HOME=${WRKDIR} \
		BUNDLE_PATH=${WRKSRC}/vendor/bundle \
		RAILS_ENV=production

NODE_ENV=	production

post-extract:
	@${CP} ${WRKSRC}/.env.example ${WRKSRC}/.env

pre-build:
	@${REINPLACE_CMD} -e \
		's/gem "mini_racer"/# gem "mini_racer" # disabled on FreeBSD/' \
		${WRKSRC}/Gemfile
	@${REINPLACE_CMD} -e \
		's/gem "execjs"/gem "execjs" # uses system Node.js/' \
		${WRKSRC}/Gemfile || true
	@${REINPLACE_CMD} -e \
		's|"prepare": "husky install"|"prepare": "true"|' \
		${WRKSRC}/package.json

do-build:
	# Install Ruby gems.
	# Bundler 4.x removed --deployment and --without as install-time flags.
	# They must now be set via 'bundle config set' before 'bundle install'.
	# This works because BUNDLE_ENV no longer overrides GEM_PATH, so bundler
	# can load itself from the system gem path during the config step.
	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
		${BUNDLE_CMD} config set --local deployment true
	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
		${BUNDLE_CMD} config set --local without 'development test'
	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
		${BUNDLE_CMD} install --jobs ${MAKE_JOBS_NUMBER}

	# Install JS dependencies.
	# HUSKY=0 prevents husky from running 'husky install' as a postinstall
	# script: husky requires a .git directory which does not exist in a port
	# build tree (extracted tarball, not a git clone).
	# --frozen-lockfile is omitted: GitHub release tarballs do not always
	# include yarn.lock, so we let yarn resolve freely and rely on the
	# Gemfile.lock / package.json version pins for reproducibility.
	cd ${WRKSRC} && ${SETENV} HOME=${WRKDIR} NODE_ENV=${NODE_ENV} \
		HUSKY=0 \
		yarn install --production=false --ignore-optional

	# Pre-compile frontend assets.
	# SECRET_KEY_BASE is consumed by Rails initializers; any non-empty value
	# works at asset-compile time.  DATABASE_URL is set to prevent any
	# accidental connection attempt during the compile phase.
	#cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
	#	SECRET_KEY_BASE=freebsd_build_placeholder \
	#	DATABASE_URL=nulldb://localhost/chatwoot \
	#	${BUNDLE_CMD} exec rails assets:precompile

	cd ${WRKSRC} && ${SETENV} ${BUNDLE_ENV} \
	    SECRET_KEY_BASE=freebsd_build_placeholder \
	    SECRET_KEY_BASE_DUMMY=1 \
	    DATABASE_URL=postgresql://localhost/chatwoot_build_dummy \
	    ${BUNDLE_CMD} exec rails assets:precompile

do-install:
	${MKDIR} ${STAGEDIR}${CHATWOOT_DIR}
	${MKDIR} ${STAGEDIR}${CHATWOOT_LOGDIR}
	${MKDIR} ${STAGEDIR}${CHATWOOT_RUNDIR}
	${MKDIR} ${STAGEDIR}${CHATWOOT_DBDIR}/storage

	cd ${WRKSRC} && ${COPYTREE_SHARE} . ${STAGEDIR}${CHATWOOT_DIR} \
		"! -path './.git*' \
		 ! -path './node_modules*' \
		 ! -path './spec*' \
		 ! -path './test*' \
		 ! -path './.github*'"

	${INSTALL_DATA} ${WRKSRC}/.env.example \
		${STAGEDIR}${CHATWOOT_DIR}/.env.sample

	${CHOWN} -R ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_DIR}
	${CHMOD} 750 ${STAGEDIR}${CHATWOOT_DIR}
	${CHOWN} ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_LOGDIR}
	${CHOWN} ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_RUNDIR}
	${CHOWN} ${USERS}:${GROUPS} ${STAGEDIR}${CHATWOOT_DBDIR}

post-install:
	${LN} -sf ${CHATWOOT_DIR}/bin/rails ${STAGEDIR}${PREFIX}/bin/chatwoot-rails
	${LN} -sf ${CHATWOOT_DIR}/bin/rake  ${STAGEDIR}${PREFIX}/bin/chatwoot-rake

.include <bsd.port.mk>
