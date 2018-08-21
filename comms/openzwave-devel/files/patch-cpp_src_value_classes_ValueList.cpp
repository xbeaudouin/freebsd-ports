--- cpp/src/value_classes/ValueList.cpp.orig	2018-08-20 16:15:51.362073000 +0200
+++ cpp/src/value_classes/ValueList.cpp	2018-08-20 16:16:53.724860000 +0200
@@ -60,7 +60,7 @@
 	m_items( _items ),
 	m_valueIdx( _valueIdx ),
 	m_valueIdxCheck( 0 ),
-	m_newValueIdx( 0 ),
+	//m_newValueIdx( 0 ),
 	m_size( _size )
 {
 }
@@ -76,7 +76,7 @@
 	m_items( ),
 	m_valueIdx(),
 	m_valueIdxCheck( 0 ),
-	m_newValueIdx( 0 ),
+	//m_newValueIdx( 0 ),
 	m_size(0)
 {
 }
