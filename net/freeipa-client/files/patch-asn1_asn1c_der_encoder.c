--- asn1/asn1c/der_encoder.c.orig	2023-10-25 10:50:02.500738000 +0200
+++ asn1/asn1c/der_encoder.c	2023-10-25 10:51:39.587231000 +0200
@@ -4,6 +4,7 @@
  */
 #include <asn_internal.h>
 #include <errno.h>
+#include <stdlib.h>
 
 static ssize_t der_write_TL(ber_tlv_tag_t tag, ber_tlv_len_t len,
 	asn_app_consume_bytes_f *cb, void *app_key, int constructed);
