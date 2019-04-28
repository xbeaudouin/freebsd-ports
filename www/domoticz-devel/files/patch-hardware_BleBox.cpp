--- hardware/BleBox.cpp.orig	2019-04-10 21:58:42.771549000 +0200
+++ hardware/BleBox.cpp	2019-04-10 22:00:01.617118000 +0200
@@ -1002,6 +1002,7 @@
 		}
 		result = root["device"]["type"].asString();
 	}
+	Log(LOG_ERROR, "Find %s device at %s", result.c_str(), IPAddress.c_str());
 	return result;
 }
 
