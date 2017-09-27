--- cpp/hidapi/mac/hid.c.orig	2017-09-27 14:30:32 UTC
+++ cpp/hidapi/mac/hid.c
@@ -1,3 +1,5 @@
+#ifdef USE_UDEV
+
 /*******************************************************
  HIDAPI - Multi-Platform library for
  communication with HID devices.
@@ -1109,3 +1111,5 @@ int main(void)
 	return 0;
 }
 #endif
+
+#endif //#ifdef USE_UDEV
