--- json/json.h.orig	2017-05-23 12:03:14.822828000 +0200
+++ json/json.h	2017-05-23 12:03:47.168154000 +0200
@@ -2,6 +2,9 @@
 // Distributed under MIT license, or public domain if desired and
 // recognized in your jurisdiction.
 // See file LICENSE for detail or copy at http://jsoncpp.sourceforge.net/LICENSE
+#ifdef WITH_EXTERNAL_JSONCPP
+#include <json/json.h>
+#else
 
 #ifndef JSON_JSON_H_INCLUDED
 #define JSON_JSON_H_INCLUDED
@@ -13,3 +16,5 @@
 #include "features.h"
 
 #endif // JSON_JSON_H_INCLUDED
+
+#endif
