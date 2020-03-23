--- hardware/DomoticzHardware.h.orig	2020-03-13 13:29:01.099837000 +0100
+++ hardware/DomoticzHardware.h	2020-03-13 13:29:51.279735000 +0100
@@ -4,10 +4,10 @@
 #include "../main/RFXNames.h"
 #include "../main/StoppableTask.h"
 // type support
-#include "../cereal/types/string.hpp"
-#include "../cereal/types/memory.hpp"
+#include <cereal/types/string.hpp>
+#include <cereal/types/memory.hpp>
 // the archiver
-#include "../cereal/archives/portable_binary.hpp"
+#include <cereal/archives/portable_binary.hpp>
 
 enum _eLogLevel : uint32_t;
 enum _eDebugLevel : uint32_t;
