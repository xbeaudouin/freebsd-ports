--- cpp/src/value_classes/ValueShort.h.orig	2018-08-20 14:06:22.696960000 +0200
+++ cpp/src/value_classes/ValueShort.h	2018-08-20 14:09:49.230398000 +0200
@@ -62,7 +62,7 @@
 	private:
 		int16	m_value;				// the current value
 		int16	m_valueCheck;			// the previous value (used for double-checking spurious value reads)
-		int16	m_newValue;				// a new value to be set on the appropriate device
+		//int16	m_newValue;				// a new value to be set on the appropriate device
 	};
 
 } // namespace OpenZWave
