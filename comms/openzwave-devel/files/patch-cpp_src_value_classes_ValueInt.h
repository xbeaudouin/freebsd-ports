--- cpp/src/value_classes/ValueInt.h.orig	2018-08-20 16:11:21.370129000 +0200
+++ cpp/src/value_classes/ValueInt.h	2018-08-20 16:11:54.991340000 +0200
@@ -62,7 +62,7 @@
 	private:
 		int32	m_value;				// the current value
 		int32	m_valueCheck;			// the previous value (used for double-checking spurious value reads)
-		int32	m_newValue;				// a new value to be set on the appropriate device
+		//int32	m_newValue;				// a new value to be set on the appropriate device
 	};
 
 } // namespace OpenZWave
