--- cpp/src/platform/unix/SerialControllerImpl.cpp.orig	2017-09-27 14:30:32 UTC
+++ cpp/src/platform/unix/SerialControllerImpl.cpp
@@ -34,10 +34,6 @@
 #include "SerialControllerImpl.h"
 #include "platform/Log.h"
 
-#ifdef __linux__
-#include <libudev.h>
-#endif
-
 using namespace OpenZWave;
 
 //-----------------------------------------------------------------------------
