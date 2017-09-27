--- cpp/hidapi/libusb/hid.c.orig	2017-09-27 14:30:32 UTC
+++ cpp/hidapi/libusb/hid.c
@@ -1,3 +1,5 @@
+#ifdef USE_UDEV
+
 /*******************************************************
  HIDAPI - Multi-Platform library for
  communication with HID devices.
@@ -1422,3 +1424,5 @@ uint16_t get_usb_code_for_current_locale
 #ifdef __cplusplus
 }
 #endif
+
+#endif //#ifdef USE_UDEV
