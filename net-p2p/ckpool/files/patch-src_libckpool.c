--- src/libckpool.c.orig	2026-05-21 22:12:11 UTC
+++ src/libckpool.c
@@ -18,7 +18,13 @@
 #endif
 #include <sys/epoll.h>
 #include <sys/file.h>
+#ifdef __FreeBSD__
+#include <pthread_np.h>
+#include <netinet/tcp.h>
+#include <libgen.h>
+#else
 #include <sys/prctl.h>
+#endif
 #include <sys/stat.h>
 #include <netdb.h>
 #include <unistd.h>
@@ -41,6 +47,13 @@
 #define UNIX_PATH_MAX 108
 #endif
 
+/* FreeBSD only */
+#ifdef __FreeBSD__
+#ifndef SOL_TCP
+#define SOL_TCP IPPROTO_TCP
+#endif
+#endif
+
 /* We use a weak function as a simple printf within the library that can be
  * overridden by however the outside executable wishes to do its logging. */
 void __attribute__((weak)) logmsg(int __maybe_unused loglevel, const char *fmt, ...)
@@ -62,7 +75,11 @@ void rename_proc(const char *name)
 
 	snprintf(buf, 15, "ckp@%s", name);
 	buf[15] = '\0';
+#ifdef __FreeBSD__
+	pthread_set_name_np(pthread_self(), buf);
+#else
 	prctl(PR_SET_NAME, buf, 0, 0, 0);
+#endif
 }
 
 void create_pthread(pthread_t *thread, void *(*start_routine)(void *), void *arg)
