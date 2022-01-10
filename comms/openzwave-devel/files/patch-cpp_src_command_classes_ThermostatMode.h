--- cpp/src/command_classes/ThermostatMode.h.orig	2022-01-10 15:55:17.264567000 +0100
+++ cpp/src/command_classes/ThermostatMode.h	2022-01-10 15:55:34.169736000 +0100
@@ -82,7 +82,7 @@
 					{
 						return 3;
 					}
-					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance);
+					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance) override;
 
 				protected:
 					virtual void CreateVars(uint8 const _instance) override;
