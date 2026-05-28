--- src/stratifier.c.orig	2026-05-28 10:19:54 UTC
+++ src/stratifier.c
@@ -9,6 +9,11 @@
 
 #include "config.h"
 
+#ifdef __FreeBSD__
+/* basename() is in <libgen.h> on FreeBSD, not implicitly via <string.h> */
+#include <libgen.h>
+#endif
+
 #include <arpa/inet.h>
 #include <sys/socket.h>
 #include <sys/stat.h>
