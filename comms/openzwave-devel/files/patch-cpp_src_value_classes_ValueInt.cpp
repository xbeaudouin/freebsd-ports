--- cpp/src/value_classes/ValueInt.cpp.orig	2018-08-20 16:11:36.905077000 +0200
+++ cpp/src/value_classes/ValueInt.cpp	2018-08-20 16:12:39.133833000 +0200
@@ -58,8 +58,7 @@
 ):
   	Value( _homeId, _nodeId, _genre, _commandClassId, _instance, _index, ValueID::ValueType_Int, _label, _units, _readOnly, _writeOnly, false, _pollIntensity ),
 	m_value( _value ),
-	m_valueCheck( 0 ),
-	m_newValue( 0 )
+	m_valueCheck( 0 )
 {
 	m_min = INT_MIN;
 	m_max = INT_MAX;
@@ -74,8 +73,7 @@
 ):
   	Value(),
 	m_value( 0 ),
-	m_valueCheck( 0 ),
-	m_newValue( 0 )
+	m_valueCheck( 0 )
 
 {
 	m_min = INT_MIN;
