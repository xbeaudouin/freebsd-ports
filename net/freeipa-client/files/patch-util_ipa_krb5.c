--- util/ipa_krb5.c.orig	2023-11-09 13:15:29.008519000 +0100
+++ util/ipa_krb5.c	2023-11-09 13:16:37.216891000 +0100
@@ -25,6 +25,7 @@
 #include <errno.h>
 #include <lber.h>
 #include <errno.h>
+#include <sys/endian.h>
 
 #include <libintl.h>
 #define _(STRING) gettext(STRING)
