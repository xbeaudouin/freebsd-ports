--- hardware/BleBox.cpp.orig	2019-05-14 13:15:16.000000000 +0200
+++ hardware/BleBox.cpp	2019-05-15 09:13:22.165923000 +0200
@@ -984,12 +984,15 @@
 	std::string sURL = sstr.str();
 	HTTPClient::SetConnectionTimeout(timeOut);
 	HTTPClient::SetTimeout(4);
+	Log(LOG_STATUS,"SendCommand( %s, %s, %d)", IPAddress.c_str(), command.c_str(), timeOut);
 	if (!HTTPClient::GET(sURL, result))
 	{
 		Log(LOG_ERROR, "send '%s'command to %s failed!", command.c_str(), IPAddress.c_str());
 		return root;
 	}
 
+	Log(LOG_STATUS,"Result of SendCommand( %s, %s, %d) = %s", IPAddress.c_str(), command.c_str(), timeOut, result.c_str());
+
 	Json::Reader jReader;
 	if (!jReader.parse(result, root))
 	{
@@ -1033,6 +1036,8 @@
 		}
 		result = root["device"]["type"].asString();
 	}
+
+	Log(LOG_STATUS,"Result of IdentifyDevice(%s) = '%s'", IPAddress.c_str(), result.c_str());
 	return result;
 }
 
@@ -1117,6 +1122,8 @@
 		return;
 
 	int deviceTypeID = GetDeviceTypeByApiName(deviceApiName);
+	Log(LOG_STATUS,"AddNode() : DeviceTypeID : %d", deviceTypeID);
+
 	if (deviceTypeID == -1)
 		return;
 
@@ -1124,8 +1131,11 @@
 
 	std::string szIdx = IPToHex(IPAddress, deviceType.deviceID);
 
+	Log(LOG_STATUS,"AddNode() : szIdx : '%s'", szIdx.c_str());
+
 	if (deviceType.unit == 4) // gatebox
 	{
+		Log(LOG_STATUS,"AddNode() : GateBox" );
 		m_sql.InsertDevice(m_HwdID, szIdx.c_str(), 1, (uint8_t)deviceType.deviceID, deviceType.subType, deviceType.switchType, 0, "Unavailable", name);
 		m_sql.InsertDevice(m_HwdID, szIdx.c_str(), 2, pTypeGeneralSwitch, sTypeAC, STYPE_PushOn, 0, "Unavailable", name);
 		m_sql.InsertDevice(m_HwdID, szIdx.c_str(), 3, pTypeGeneralSwitch, sTypeAC, STYPE_PushOn, 0, "Unavailable", name);
@@ -1133,11 +1143,13 @@
 	else
 		if (deviceType.unit == 6) // switchboxd
 		{
+			Log(LOG_STATUS,"AddNode() : SwitchBoxd" );
 			m_sql.InsertDevice(m_HwdID, szIdx.c_str(), 0, (uint8_t)deviceType.deviceID, deviceType.subType, deviceType.switchType, 0, "Unavailable", name);
 			m_sql.InsertDevice(m_HwdID, szIdx.c_str(), 1, (uint8_t)deviceType.deviceID, deviceType.subType, deviceType.switchType, 0, "Unavailable", name);
 		}
 		else
 		{
+			Log(LOG_STATUS,"AddNode() : Other" );
 			m_sql.InsertDevice(m_HwdID, szIdx.c_str(), 0, (uint8_t)deviceType.deviceID, deviceType.subType, deviceType.switchType, 0, "Unavailable", name);
 		}
 	ReloadNodes();
@@ -1168,10 +1180,14 @@
 {
 	std::lock_guard<std::mutex> l(m_mutex);
 
+	Log(LOG_STATUS,"LoadNodes()");
+
 	std::vector<std::vector<std::string> > result;
 	result = m_sql.safe_query("SELECT ID,DeviceID FROM DeviceStatus WHERE (HardwareID==%d)", m_HwdID);
+	Log(LOG_STATUS,"LoadNodes() - QUERY");
 	if (!result.empty())
 	{
+		Log(LOG_STATUS,"LoadNodes() - QUERY not empty");
 		for (const auto& itt : result)
 		{
 			const std::vector<std::string>& sd = itt;
@@ -1191,7 +1207,7 @@
 	}
 	else
 	{
-		Log(LOG_ERROR, "Cannot find any devices...");
+		Log(LOG_ERROR, "LoadNodes() Cannot find any devices...");
 		return false;
 	}
 }
