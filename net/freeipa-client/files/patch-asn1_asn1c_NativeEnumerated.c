--- asn1/asn1c/NativeEnumerated.c.orig	2023-10-25 10:55:37.747932000 +0200
+++ asn1/asn1c/NativeEnumerated.c	2023-10-25 10:56:03.939387000 +0200
@@ -11,6 +11,7 @@
  */
 #include <asn_internal.h>
 #include <NativeEnumerated.h>
+#include <stdlib.h>
 
 /*
  * NativeEnumerated basic type description.
