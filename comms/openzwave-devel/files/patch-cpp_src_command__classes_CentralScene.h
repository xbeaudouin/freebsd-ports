--- cpp/src/command_classes/CentralScene.h.orig	2017-09-27 14:30:32 UTC
+++ cpp/src/command_classes/CentralScene.h
@@ -52,10 +52,19 @@ namespace OpenZWave
 		virtual uint8 const GetCommandClassId()const{ return StaticGetCommandClassId(); }
 		/** \brief Get a string containing the name of this command class. (Inherited from CommandClass) */
 		virtual string const GetCommandClassName()const{ return StaticGetCommandClassName(); }
+		virtual uint8 GetMaxVersion(){ return 3; }
 		/** \brief Handle a response to a message associated with this command class. (Inherited from CommandClass) */
 		virtual bool HandleMsg( uint8 const* _data, uint32 const _length, uint32 const _instance = 1 );
 		/** \brief Create Default Vars for this CC */
 		void CreateVars( uint8 const _instance );
+		/**
+		 * Creates the ValueIDs for the keyAttributes
+		 * @param identical
+		 * @param keyAttributes
+		 * @param sceneNumber
+		 * @return
+		 */
+		void createSupportedKeyAttributesValues(uint8 keyAttributes, uint8 sceneNumber, uint8 index, uint8 instance);
 		void ReadXML( TiXmlElement const* _ccElement	);
 		void WriteXML( TiXmlElement* _ccElement );
 		bool RequestState( uint32 const _requestFlags, uint8 const _instance, Driver::MsgQueue const _queue );
@@ -68,4 +77,3 @@ namespace OpenZWave
 } // namespace OpenZWave
 
 #endif
-
