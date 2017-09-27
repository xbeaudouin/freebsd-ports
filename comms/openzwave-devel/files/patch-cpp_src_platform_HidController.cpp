--- cpp/src/platform/HidController.cpp.orig	2017-09-27 14:30:32 UTC
+++ cpp/src/platform/HidController.cpp
@@ -1,3 +1,5 @@
+#ifdef USE_UDEV
+
 //-----------------------------------------------------------------------------
 //
 //	HidController.h
@@ -539,3 +541,5 @@ int HidController::SendFeatureReport
 	return result;
 }
 
+#endif //#ifdef USE_UDEV
+
