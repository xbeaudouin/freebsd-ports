--- cpp/src/value_classes/ValueByte.h.orig	2018-08-20 16:07:49.016149000 +0200
+++ cpp/src/value_classes/ValueByte.h	2018-08-20 16:08:12.430084000 +0200
@@ -62,7 +62,7 @@
 	private:
 		uint8	m_value;				// the current value
 		uint8	m_valueCheck;			// the previous value (used for double-checking spurious value reads)
-		uint8	m_newValue;				// a new value to be set on the appropriate device
+		//uint8	m_newValue;				// a new value to be set on the appropriate device
 	};
 
 } // namespace OpenZWave
