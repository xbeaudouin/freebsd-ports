--- cpp/hidapi/linux/hid.c.orig	2017-09-27 14:30:32 UTC
+++ cpp/hidapi/linux/hid.c
@@ -1,3 +1,5 @@
+#ifdef USE_UDEV
+
 /*******************************************************
  HIDAPI - Multi-Platform library for
  communication with HID devices.
@@ -792,3 +794,6 @@ HID_API_EXPORT const wchar_t * HID_API_C
 {
 	return NULL;
 }
+
+#endif //#ifdef USE_UDEV
+
