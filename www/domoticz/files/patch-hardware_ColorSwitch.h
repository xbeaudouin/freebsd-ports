--- hardware/ColorSwitch.h.orig	2020-03-13 13:27:39.171546000 +0100
+++ hardware/ColorSwitch.h	2020-03-13 13:27:55.664840000 +0100
@@ -1,5 +1,7 @@
 #pragma once
 
+#include <cereal/cereal.hpp>
+
 namespace Json
 {
 	class Value;
