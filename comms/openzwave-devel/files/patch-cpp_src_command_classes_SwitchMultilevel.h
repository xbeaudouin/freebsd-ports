--- cpp/src/command_classes/SwitchMultilevel.h.orig	2022-01-10 15:56:35.835668000 +0100
+++ cpp/src/command_classes/SwitchMultilevel.h	2022-01-10 15:56:51.895100000 +0100
@@ -79,7 +79,7 @@
 					{
 						return 4;
 					}
-					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance);
+					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance) override;
 
 				protected:
 					virtual void CreateVars(uint8 const _instance) override;
