--- cpp/src/Driver.cpp.orig	2017-09-27 14:30:32 UTC
+++ cpp/src/Driver.cpp
@@ -37,11 +37,13 @@
 #include "platform/Event.h"
 #include "platform/Mutex.h"
 #include "platform/SerialController.h"
+#ifdef USE_UDEV
 #ifdef WINRT
 #include "platform/winRT/HidControllerWinRT.h"
 #else
 #include "platform/HidController.h"
 #endif
+#endif //#ifdef USE_UDEV
 #include "platform/Thread.h"
 #include "platform/Log.h"
 #include "platform/TimeStamp.h"
@@ -222,12 +224,13 @@ m_nonceReportSentAttempt( 0 )
 	// Initilize the Network Keys
 
 	initNetworkKeys(false);
-
+#ifdef USE_UDEV
 	if( ControllerInterface_Hid == _interface )
 	{
 		m_controller = new HidController();
 	}
 	else
+#endif //#ifdef USE_UDEV
 	{
 		m_controller = new SerialController();
 	}
