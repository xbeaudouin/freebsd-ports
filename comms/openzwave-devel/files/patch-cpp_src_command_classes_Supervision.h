--- cpp/src/command_classes/Supervision.h.orig	2022-01-10 15:45:28.199964000 +0100
+++ cpp/src/command_classes/Supervision.h	2022-01-10 15:49:28.901581000 +0100
@@ -79,12 +79,12 @@
 						return "COMMAND_CLASS_SUPERVISION";
 					}
 
-					uint8 CreateSupervisionSession(uint8 _command_class_id, uint8 _index);
+					uint8 CreateSupervisionSession(uint8 _command_class_id, uint8 _index) override;
 					static uint8 const StaticNoSessionId()
 					{
 						return 0xff; // As sessions are only 5 bits, this value will never match
 					}
-					uint32 GetSupervisionIndex(uint8 _session_id);
+					uint32 GetSupervisionIndex(uint8 _session_id) override;
 					static uint32 const StaticNoIndex()
 					{
 						return 0xffff; // As indices are max 16 bits, this value will never match
