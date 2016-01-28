--- hardware/MQTT.h.orig	2016-01-22 17:32:59.455772000 +0100
+++ hardware/MQTT.h	2016-01-22 17:34:41.761153000 +0100
@@ -1,7 +1,11 @@
 #pragma once
 
 #include "MySensorsBase.h"
+#ifdef BUILTIN_MQTT
 #include "../MQTT/mosquittopp.h"
+#else
+#include <mosquittopp.h>
+#endif
 
 class MQTT : public MySensorsBase, mosqpp::mosquittopp
 {
