--- cpp/hidapi/hidapi/hidapi.h.orig	2017-09-27 14:30:32 UTC
+++ cpp/hidapi/hidapi/hidapi.h
@@ -1,3 +1,5 @@
+#ifdef USE_UDEV
+
 /*******************************************************
  HIDAPI - Multi-Platform library for
  communication with HID devices.
@@ -383,3 +385,5 @@ extern "C" {
 
 #endif
 
+#endif //#ifdef USE_UDEV
+
