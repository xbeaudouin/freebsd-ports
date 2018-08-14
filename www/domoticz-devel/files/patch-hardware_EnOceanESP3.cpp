--- hardware/EnOceanESP3.cpp.orig	2018-08-14 10:45:26.398597000 +0200
+++ hardware/EnOceanESP3.cpp	2018-08-14 10:48:54.469723000 +0200
@@ -1895,7 +1895,7 @@
 								_log.Log(LOG_NORM, "EnOcean: Sender_ID 0x%08lX already in the database", id);
 						}
 
-						if((rorg == 0xD2) && (func == 0x01) && ( (type == 0x12) || (type == 0x0F) ))
+						if((rorg == 0xD2) && (func == 0x01) && ( (type == 0x12) || (type == 0x0F) || (type == 0x01) ))
 						{
 							unsigned char nbc;
 
