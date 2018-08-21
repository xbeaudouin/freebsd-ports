--- cpp/src/value_classes/ValueByte.cpp.orig	2018-08-20 16:07:55.182904000 +0200
+++ cpp/src/value_classes/ValueByte.cpp	2018-08-20 16:08:34.350706000 +0200
@@ -57,8 +57,8 @@
 ):
 	Value( _homeId, _nodeId, _genre, _commandClassId, _instance, _index, ValueID::ValueType_Byte, _label, _units, _readOnly, _writeOnly, false, _pollIntensity ),
 	m_value( _value ),
-	m_valueCheck( false ),
-	m_newValue( false )
+	m_valueCheck( false )
+	//m_newValue( false )
 {
 	m_min = 0;
 	m_max = 255;
