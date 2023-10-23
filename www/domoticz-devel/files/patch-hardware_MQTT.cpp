--- hardware/MQTT.cpp.orig	2023-10-23 10:38:34.428271000 +0200
+++ hardware/MQTT.cpp	2023-10-23 10:39:53.492112000 +0200
@@ -622,7 +622,7 @@
 		std::string ca_path = (!m_CAFilename.empty()) ? m_CAFilename : szCertFile;
 		rc = tls_set(ca_path.c_str());
 		if (rc != MOSQ_ERR_SUCCESS) {
-			Log(LOG_ERROR, "Failed enabling TLS mode (tls_set(%s), return code: %d)", ca_path, rc);
+			Log(LOG_ERROR, "Failed enabling TLS mode (tls_set(%s), return code: %d)", ca_path.c_str(), rc);
 			return false;
 		}
 		rc = tls_insecure_set(true);
