--- asn1/asn1c/INTEGER.c.orig	2023-10-25 10:56:17.099307000 +0200
+++ asn1/asn1c/INTEGER.c	2023-10-25 10:56:30.656530000 +0200
@@ -7,6 +7,7 @@
 #include <INTEGER.h>
 #include <asn_codecs_prim.h>	/* Encoder and decoder of a primitive type */
 #include <errno.h>
+#include <stdlib.h>
 
 /*
  * INTEGER basic type description.
