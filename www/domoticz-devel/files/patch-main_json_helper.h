--- main/json_helper.h.orig	2020-02-28 16:42:09.926203000 +0100
+++ main/json_helper.h	2020-02-28 16:42:52.810406000 +0100
@@ -1,6 +1,10 @@
 #pragma once
 
+#ifdef WITH_EXTERNAL_JSONCPP
+#include <json/json.h>
+#else
 #include "../json/json.h"
+#endif
 
 bool ParseJSon(const std::string& inStr, Json::Value& json_output, std::string* errstr = nullptr);
 bool ParseJSonStrict(const std::string& inStr, Json::Value& json_output, std::string* errstr = nullptr);
