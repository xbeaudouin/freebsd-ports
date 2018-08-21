--- cpp/src/value_classes/ValueShort.cpp.orig	2018-08-06 06:18:46.000000000 +0200
+++ cpp/src/value_classes/ValueShort.cpp	2018-08-20 16:05:45.974628000 +0200
@@ -58,8 +58,8 @@
 ):
   	Value( _homeId, _nodeId, _genre, _commandClassId, _instance, _index, ValueID::ValueType_Short, _label, _units, _readOnly, _writeOnly, false, _pollIntensity ),
 	m_value( _value ),
-	m_valueCheck( 0 ),
-	m_newValue( 0 )
+	m_valueCheck( 0 )
+	//m_newValue( 0 )
 {
 	m_min = SHRT_MIN;
 	m_max = SHRT_MAX;
@@ -74,8 +74,8 @@
 ):
 	Value(),
 	m_value( 0 ),
-	m_valueCheck( 0 ),
-	m_newValue( 0 )
+	m_valueCheck( 0 )
+	//m_newValue( 0 )
 {
 	m_min = SHRT_MIN;
 	m_max = SHRT_MAX;
