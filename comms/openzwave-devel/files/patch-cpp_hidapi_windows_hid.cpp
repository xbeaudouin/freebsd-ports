--- cpp/hidapi/windows/hid.cpp.orig	2017-09-27 14:30:32 UTC
+++ cpp/hidapi/windows/hid.cpp
@@ -1,3 +1,5 @@
+#ifdef USE_UDEV
+
 /*******************************************************
  HIDAPI - Multi-Platform library for
  communication with HID devices.
@@ -918,3 +920,5 @@ int __cdecl main(int argc, char* argv[])
 #ifdef __cplusplus
 } /* extern "C" */
 #endif
+
+#endif //#ifdef USE_UDEV
