PORTNAME=	etcd
PORTVERSION=	3.5.15
DISTVERSIONPREFIX=	v
CATEGORIES=	devel
PKGNAMEPREFIX=	coreos-

MAINTAINER=	kiwi@oav.net
COMMENT=	Highly-available key value store and service discovery
WWW=		https://github.com/coreos/etcd

LICENSE=	APACHE20
LICENSE_FILE=	${WRKSRC}/LICENSE

USES=		cpe go:1.21,modules
USE_GITHUB=	yes
GH_ACCOUNT=	coreos
GH_TUPLE=	\
		beorn7:perks:v1.0.1:beorn7_perks/vendor/github.com/beorn7/perks \
		bgentry:speakeasy:v0.1.0:bgentry_speakeasy/vendor/github.com/bgentry/speakeasy \
		cenkalti:backoff:v4.2.1:cenkalti_backoff_v4/vendor/github.com/cenkalti/backoff/v4 \
		cespare:xxhash:v2.2.0:cespare_xxhash_v2/vendor/github.com/cespare/xxhash/v2 \
		cheggaaa:pb:v1.0.28:cheggaaa_pb/vendor/gopkg.in/cheggaaa/pb.v1 \
		coreos:go-semver:v0.3.0:coreos_go_semver/vendor/github.com/coreos/go-semver \
		coreos:go-systemd:v22.3.2:coreos_go_systemd_v22/vendor/github.com/coreos/go-systemd/v22 \
		dustin:go-humanize:v1.0.0:dustin_go_humanize/vendor/github.com/dustin/go-humanize \
		etcd-io:bbolt:v1.3.10:etcd_io_bbolt/vendor/go.etcd.io/bbolt \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd/go.etcd.io/etcd/api/v3 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_11/go.etcd.io/etcd/etcdutl/v3 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_12/go.etcd.io/etcd/pkg/v3 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_14/go.etcd.io/etcd/raft/v3 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_17/go.etcd.io/etcd/server/v3 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_2/go.etcd.io/etcd/client/pkg/v3 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_6/go.etcd.io/etcd/client/v3 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_8/go.etcd.io/etcd/etcdctl/v3 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_10 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_13 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_15 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_16 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_19 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_1 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_3 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_7 \
		etcd-io:etcd:v3.5.15:etcd_io_etcd_9 \
		etcd-io:etcd:v3.6.0-alpha.0:etcd_io_etcd_4/go.etcd.io/etcd/client/v2 \
		go-logr:logr:v1.3.0:go_logr_logr/vendor/github.com/go-logr/logr \
		go-logr:stdr:v1.2.2:go_logr_stdr/vendor/github.com/go-logr/stdr \
		go-yaml:yaml:v2.4.0:go_yaml_yaml/vendor/gopkg.in/yaml.v2 \
		gogo:protobuf:v1.3.2:gogo_protobuf/vendor/github.com/gogo/protobuf \
		golang-jwt:jwt:v4.4.2:golang_jwt_jwt_v4/vendor/github.com/golang-jwt/jwt/v4 \
		golang:crypto:v0.21.0:golang_crypto/vendor/golang.org/x/crypto \
		golang:groupcache:41bb18bfe9da:golang_groupcache/vendor/github.com/golang/groupcache \
		golang:net:v0.23.0:golang_net/vendor/golang.org/x/net \
		golang:protobuf:v1.5.4:golang_protobuf/vendor/github.com/golang/protobuf \
		golang:sys:v0.18.0:golang_sys/vendor/golang.org/x/sys \
		golang:text:v0.14.0:golang_text/vendor/golang.org/x/text \
		golang:time:f8bda1e9f3ba:golang_time/vendor/golang.org/x/time \
		google:btree:v1.0.1:google_btree/vendor/github.com/google/btree \
		google:go-genproto:b8732ec3820d:google_go_genproto/vendor/google.golang.org/genproto \
		gorilla:websocket:v1.4.2:gorilla_websocket/vendor/github.com/gorilla/websocket \
		grpc-ecosystem:go-grpc-middleware:v1.3.0:grpc_ecosystem_go_grpc_middleware/vendor/github.com/grpc-ecosystem/go-grpc-middleware \
		grpc-ecosystem:go-grpc-prometheus:v1.2.0:grpc_ecosystem_go_grpc_prometheus/vendor/github.com/grpc-ecosystem/go-grpc-prometheus \
		grpc-ecosystem:grpc-gateway:v1.16.0:grpc_ecosystem_grpc_gateway/vendor/github.com/grpc-ecosystem/grpc-gateway \
		grpc-ecosystem:grpc-gateway:v2.16.0:grpc_ecosystem_grpc_gateway_v2/vendor/github.com/grpc-ecosystem/grpc-gateway/v2 \
		grpc:grpc-go:v1.59.0:grpc_grpc_go/vendor/google.golang.org/grpc \
		inconshreveable:mousetrap:v1.0.0:inconshreveable_mousetrap/vendor/github.com/inconshreveable/mousetrap \
		jonboulle:clockwork:v0.2.2:jonboulle_clockwork/vendor/github.com/jonboulle/clockwork \
		json-iterator:go:v1.1.11:json_iterator_go/vendor/github.com/json-iterator/go \
		kubernetes-sigs:yaml:v1.2.0:kubernetes_sigs_yaml/vendor/sigs.k8s.io/yaml \
		mattn:go-colorable:v0.1.11:mattn_go_colorable/vendor/github.com/mattn/go-colorable \
		mattn:go-runewidth:v0.0.9:mattn_go_runewidth/vendor/github.com/mattn/go-runewidth \
		matttproud:golang_protobuf_extensions:v1.0.1:matttproud_golang_protobuf_extensions/vendor/github.com/matttproud/golang_protobuf_extensions \
		modern-go:concurrent:bacd9c7ef1dd:modern_go_concurrent/vendor/github.com/modern-go/concurrent \
		modern-go:reflect2:v1.0.1:modern_go_reflect2/vendor/github.com/modern-go/reflect2 \
		natefinch:lumberjack:v2.0.0:natefinch_lumberjack/vendor/gopkg.in/natefinch/lumberjack.v2 \
		olekukonko:tablewriter:v0.0.5:olekukonko_tablewriter/vendor/github.com/olekukonko/tablewriter \
		open-telemetry:opentelemetry-go-contrib:instrumentation/google.golang.org/grpc/otelgrpc/v0.46.0:open_telemetry_opentelemetry_go_contrib/vendor/go.opentelemetry.io/contrib \
		open-telemetry:opentelemetry-go:v1.20.0:open_telemetry_opentelemetry_go/vendor/go.opentelemetry.io/otel \
		open-telemetry:opentelemetry-proto-go:v1.0.0:open_telemetry_opentelemetry_proto_go/vendor/go.opentelemetry.io/proto/otlp \
		prometheus:client_golang:v1.11.1:prometheus_client_golang/vendor/github.com/prometheus/client_golang \
		prometheus:client_model:v0.2.0:prometheus_client_model/vendor/github.com/prometheus/client_model \
		prometheus:common:v0.26.0:prometheus_common/vendor/github.com/prometheus/common \
		prometheus:procfs:v0.6.0:prometheus_procfs/vendor/github.com/prometheus/procfs \
		protocolbuffers:protobuf-go:v1.33.0:protocolbuffers_protobuf_go/vendor/google.golang.org/protobuf \
		sirupsen:logrus:v1.9.3:sirupsen_logrus/vendor/github.com/sirupsen/logrus \
		soheilhy:cmux:v0.1.5:soheilhy_cmux/vendor/github.com/soheilhy/cmux \
		spf13:cobra:v1.1.3:spf13_cobra/vendor/github.com/spf13/cobra \
		spf13:pflag:v1.0.5:spf13_pflag/vendor/github.com/spf13/pflag \
		tmc:grpc-websocket-proxy:e5319fda7802:tmc_grpc_websocket_proxy/vendor/github.com/tmc/grpc-websocket-proxy \
		uber-go:atomic:v1.7.0:uber_go_atomic/vendor/go.uber.org/atomic \
		uber-go:multierr:v1.6.0:uber_go_multierr/vendor/go.uber.org/multierr \
		uber-go:zap:v1.17.0:uber_go_zap/vendor/go.uber.org/zap \
		xiang90:probing:43a291ad63a2:xiang90_probing/vendor/github.com/xiang90/probing

		#etcd-io:etcd:v3.0.0-00010101000000-000000000000:etcd_io_etcd_18/go.etcd.io/etcd/tests/v3 \
		#etcd-io:etcd:v2.306.0-alpha.0:etcd_io_etcd_4/go.etcd.io/etcd/client/v2 \
		#etcd-io:etcd:v2.305.15:etcd_io_etcd_5 \

GO_PKGNAME=	github.com/coreos/etcd
GO_TARGET=	./server ./etcdctl ./etcdutl

CONFLICTS_INSTALL=	coreos-etcd[0-9][0-9]

PLIST_FILES=	bin/etcd \
		bin/etcdctl
PORTDOCS=	README.md

OPTIONS_DEFINE=	DOCS
DOCS_DESC=	Install etcd README file

#pre-patch:
#	${RM} ${WRKSRC}/vendor/modules.txt
#	${RM} -r ${WRKSRC}/vendor/golang.org/x/sys
#	${LN} -s ${WRKDIR}/sys-* ${WRKSRC}/vendor/golang.org/x/sys

post-extract:
	${RLN} ${WRKSRC_etcd_io_etcd_1} ${WRKSRC}/api
	#${RLN} ${WRKSRC_etcd_io_etcd} ${WRKSRC}/api
	${RLN} ${WRKSRC_etcd_io_etcd_3} ${WRKSRC}/client/pkg
	#${RLN} ${WRKSRC_etcd_io_etcd_2} ${WRKSRC}/client/pkg
	#${RLN} ${WRKSRC_etcd_io_etcd_4} ${WRKSRC}/client/v2
	#${RLN} ${WRKSRC_etcd_io_etcd_5} ${WRKSRC}/client/v2
	${RLN} ${WRKSRC_etcd_io_etcd_7} ${WRKSRC}/client/v3
	#${RLN} ${WRKSRC_etcd_io_etcd_6} ${WRKSRC}/client/v3
	${RLN} ${WRKSRC_etcd_io_etcd_9} ${WRKSRC}/etcdctl
	#${RLN} ${WRKSRC_etcd_io_etcd_8} ${WRKSRC}/etcdctl
	#${RLN} ${WRKSRC_etcd_io_etcd_11} ${WRKSRC}/etcdutl
	${RLN} ${WRKSRC_etcd_io_etcd_10} ${WRKSRC}/etcdutl
	${RLN} ${WRKSRC_etcd_io_etcd_13} ${WRKSRC}/pkg
	#${RLN} ${WRKSRC_etcd_io_etcd_12} ${WRKSRC}/pkg
	${RLN} ${WRKSRC_etcd_io_etcd_15} ${WRKSRC}/raft
	#${RLN} ${WRKSRC_etcd_io_etcd_14} ${WRKSRC}/raft
	${RLN} ${WRKSRC_etcd_io_etcd_16} ${WRKSRC}/server
	#${RLN} ${WRKSRC_etcd_io_etcd_17} ${WRKSRC}/server
	#${RLN} ${WRKSRC_etcd_io_etcd_18} ${WRKSRC}/tests
	${RLN} ${WRKSRC_etcd_io_etcd_19} ${WRKSRC}/tests

do-install-DOCS-on:
	${MKDIR} ${STAGEDIR}${DOCSDIR}
	${INSTALL_DATA} ${WRKSRC}/README.md ${STAGEDIR}${DOCSDIR}

.include <bsd.port.mk>
