--- cpp/src/Group.cpp.orig	2018-08-21 09:40:33.753932000 +0200
+++ cpp/src/Group.cpp	2018-08-21 09:41:10.674260000 +0200
@@ -536,8 +536,7 @@
 (
 	uint8 const _length,
 	uint8 const* _data
-):
-	m_length( _length )
+)
 {
 	m_data = new uint8[_length];
 	memcpy( m_data, _data, _length );
