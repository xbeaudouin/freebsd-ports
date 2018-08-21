--- cpp/src/value_classes/ValueBool.h.orig	2018-08-20 14:03:44.023667000 +0200
+++ cpp/src/value_classes/ValueBool.h	2018-08-20 14:08:22.581430000 +0200
@@ -63,7 +63,7 @@
 	private:
 		bool	m_value;				// the current index in the m_items vector
 		bool	m_valueCheck;			// the previous value (used for double-checking spurious value reads)
-		bool	m_newValue;				// a new value to be set on the appropriate device
+		//bool	m_newValue;				// a new value to be set on the appropriate device
 	};
 
 } // namespace OpenZWave
