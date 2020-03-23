--- webserver/proxycereal.hpp.orig	2020-03-13 13:33:32.145058000 +0100
+++ webserver/proxycereal.hpp	2020-03-13 13:34:43.310574000 +0100
@@ -3,11 +3,11 @@
 #include <string>
 #include <sstream>
 // type support
-#include "../cereal/types/string.hpp"
-#include "../cereal/types/memory.hpp"
+#include <cereal/types/string.hpp>
+#include <cereal/types/memory.hpp>
 // the archiver
-#include "../cereal/archives/portable_binary.hpp"
-#include "../cereal/archives/json.hpp"
+#include <cereal/archives/portable_binary.hpp>
+#include <cereal/archives/json.hpp>
 #include <string>
 
 #define SUBSYSTEM_HTTP 0x01
