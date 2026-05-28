--- src/ckpool.c.orig	2026-05-21 22:12:11 UTC
+++ src/ckpool.c
@@ -10,7 +10,13 @@
 #include "config.h"
 
 #include <sys/ioctl.h>
+#ifdef __FreeBSD__
+#include <pthread_np.h>
+#include <libgen.h>
+#include <netinet/in.h>
+#else
 #include <sys/prctl.h>
+#endif
 #include <sys/socket.h>
 #include <sys/stat.h>
 #include <sys/types.h>
@@ -32,6 +38,16 @@
 #include "stratifier.h"
 #include "connector.h"
 
+/* FreeBSD Only */
+#ifdef __FreeBSD__
+#ifndef SO_SNDBUFFORCE 
+#define SO_SNDBUFFORCE SO_SNDBUF
+#endif
+#ifndef SO_RCVBUFFORCE 
+#define SO_RCVBUFFORCE SO_RCVBUF
+#endif
+#endif
+
 ckpool_t *global_ckp;
 
 static bool open_logfile(ckpool_t *ckp)
@@ -1708,7 +1724,11 @@ int main(int argc, char **argv)
 			ckp.name = "ckpool";
 	}
 	snprintf(buf, 15, "%s", ckp.name);
-	prctl(PR_SET_NAME, buf, 0, 0, 0);
+	#ifdef __FreeBSD__
+	pthread_set_name_np(pthread_self(), buf);
+	#else
+        prctl(PR_SET_NAME, buf, 0, 0, 0);
+	#endif
 	memset(buf, 0, 15);
 
 	if (ckp.grpnam) {
