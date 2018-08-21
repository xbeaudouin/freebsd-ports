--- cpp/src/value_classes/ValueList.h.orig	2018-08-20 16:15:39.490488000 +0200
+++ cpp/src/value_classes/ValueList.h	2018-08-20 16:16:17.768333000 +0200
@@ -82,7 +82,7 @@
 		vector<Item>	m_items;
 		int32			m_valueIdx;					// the current index in the m_items vector
 		int32			m_valueIdxCheck;			// the previous index in the m_items vector (used for double-checking spurious value reads)
-		int32			m_newValueIdx;				// a new value to be set on the appropriate device
+		//int32			m_newValueIdx;				// a new value to be set on the appropriate device
 		uint8			m_size;
 	};
 
