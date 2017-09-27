--- cpp/src/platform/HidController.h.orig	2017-09-27 14:30:32 UTC
+++ cpp/src/platform/HidController.h
@@ -1,3 +1,5 @@
+#ifdef USE_UDEV
+
 //-----------------------------------------------------------------------------
 //
 //	HidController.h
@@ -149,3 +151,5 @@ namespace OpenZWave
 
 #endif //_HidController_H
 
+#endif //#ifdef USE_UDEV
+
