--- cpp/src/command_classes/ThermostatSetpoint.h.orig	2022-01-10 15:53:23.556035000 +0100
+++ cpp/src/command_classes/ThermostatSetpoint.h	2022-01-10 15:53:42.564658000 +0100
@@ -80,7 +80,7 @@
 					{
 						return 3;
 					}
-					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance);
+					virtual void SupervisionSessionSuccess(uint8 _session_id, uint32 const _instance) override;
 
 				protected:
 					virtual void CreateVars(uint8 const _instance) override;
