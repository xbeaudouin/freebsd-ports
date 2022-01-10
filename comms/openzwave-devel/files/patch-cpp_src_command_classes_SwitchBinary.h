--- cpp/src/command_classes/SwitchBinary.h.orig	2022-01-10 15:51:05.342413000 +0100
+++ cpp/src/command_classes/SwitchBinary.h	2022-01-10 15:51:20.795327000 +0100
@@ -80,7 +80,7 @@
 					{
 						return 2;
 					}
-					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance);
+					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance) override;
 
 				protected:
 					virtual void CreateVars(uint8 const _instance) override;
