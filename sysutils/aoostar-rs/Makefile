PORTNAME=	aoostar-rs
DISTVERSIONPREFIX=	v
DISTVERSION=	0.2.0
PORTREVISION=	0
CATEGORIES=	sysutils

MAINTAINER=	ports@FreeBSD.org
COMMENT=	AOOSTAR WTR MAX / GEM12+ PRO LCD screen control tool
WWW=		https://github.com/zehnm/aoostar-rs

LICENSE=	APACHE20 MIT
LICENSE_COMB=	dual
LICENSE_FILE_APACHE20=	${WRKSRC}/LICENSE-APACHE
LICENSE_FILE_MIT=	${WRKSRC}/LICENSE-MIT

# Requires at least Rust 1.88
USES=		cargo
USE_GITHUB=	yes
GH_ACCOUNT=	zehnm

# Build both binaries
CARGO_INSTALL_PATH=	crates/asterctl \
			crates/aster-sysinfo

# FreeBSD: device is /dev/cuaU0 instead of Linux /dev/ttyACM0
# The user can override at runtime with -d /dev/cuaU0

# Vendor all crates offline (run `make cargo-crates` to regenerate this list)
CARGO_CRATES=	\
	adler2-2.0.0 \
	anstream-0.6.18 \
	anstyle-1.0.10 \
	anstyle-parse-0.2.6 \
	anstyle-query-1.1.2 \
	anstyle-wincon-3.0.7 \
	bitflags-2.9.1 \
	bytemuck-1.22.0 \
	cfg-if-1.0.1 \
	chrono-0.4.41 \
	clap-4.5.40 \
	clap_builder-4.5.40 \
	clap_derive-4.5.40 \
	clap_lex-0.7.4 \
	color_quant-1.1.0 \
	colorchoice-1.0.3 \
	crc32fast-1.4.2 \
	crossbeam-channel-0.5.15 \
	crossbeam-utils-0.8.21 \
	deflate64-0.1.9 \
	either-1.15.0 \
	exr-1.73.0 \
	fdeflate-0.3.7 \
	flate2-1.1.1 \
	fnv-1.0.7 \
	gif-0.13.1 \
	half-2.6.0 \
	hashbrown-0.15.3 \
	image-0.25.6 \
	image-webp-0.2.1 \
	imageproc-0.25.0 \
	indexmap-2.9.0 \
	is_terminal_polyfill-1.70.1 \
	itertools-0.13.0 \
	jpeg-decoder-0.3.1 \
	lebe-0.5.2 \
	libc-0.2.174 \
	lock_api-0.4.12 \
	log-0.4.27 \
	miniz_oxide-0.8.8 \
	nalgebra-0.33.2 \
	nalgebra-macros-0.2.2 \
	num-complex-0.4.6 \
	num-integer-0.1.46 \
	num-iter-0.1.45 \
	num-rational-0.4.2 \
	num-traits-0.2.19 \
	once_cell-1.21.3 \
	parking_lot-0.12.3 \
	parking_lot_core-0.9.10 \
	png-0.17.16 \
	proc-macro2-1.0.95 \
	quote-1.0.40 \
	rawpointer-0.2.1 \
	rayon-1.10.0 \
	rayon-core-1.12.1 \
	regex-1.11.1 \
	regex-automata-0.4.9 \
	regex-syntax-0.8.5 \
	rustix-1.0.7 \
	scopeguard-1.2.0 \
	serde-1.0.219 \
	serde_derive-1.0.219 \
	serde_json-1.0.140 \
	serialport-4.7.1 \
	simba-0.9.0 \
	smallvec-1.15.0 \
	strsim-0.11.1 \
	syn-2.0.101 \
	sysinfo-0.34.2 \
	termcolor-1.4.1 \
	thiserror-2.0.12 \
	thiserror-impl-2.0.12 \
	tiff-0.9.1 \
	unicode-ident-1.0.18 \
	utf8parse-0.2.2 \
	weezl-0.1.8 \
	wide-0.7.32 \
	zune-inflate-0.2.54

PLIST_FILES=	bin/asterctl \
		bin/aster-sysinfo \
		"@sample ${ETCDIR}/aoostar/monitor.json.sample" \
		share/doc/${PORTNAME}/README.md

SUB_FILES=	aoostar-lcd
SUB_LIST=	ASTERCTL=${PREFIX}/bin/asterctl \
		DEVICE=/dev/cuaU0

USE_RC_SUBR=	aoostar-lcd

PORTDOCS=	README.md

OPTIONS_DEFINE=	DOCS

.include <bsd.port.mk>
