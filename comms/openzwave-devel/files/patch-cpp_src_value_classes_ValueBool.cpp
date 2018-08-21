--- cpp/src/value_classes/ValueBool.cpp.orig	2018-08-06 06:18:46.000000000 +0200
+++ cpp/src/value_classes/ValueBool.cpp	2018-08-20 16:05:12.539131000 +0200
@@ -57,8 +57,8 @@
 ):
   	Value( _homeId, _nodeId, _genre, _commandClassId, _instance, _index, ValueID::ValueType_Bool, _label, _units, _readOnly, _writeOnly, false, _pollIntensity ),
 	m_value( _value ),
-	m_valueCheck( false ),
-	m_newValue( false )
+	m_valueCheck( false )
+	//m_newValue( false )
 {
 }
 
