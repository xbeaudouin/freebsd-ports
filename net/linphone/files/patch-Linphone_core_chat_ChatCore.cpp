--- Linphone/core/chat/ChatCore.cpp.orig	2026-03-29 12:52:00 UTC
+++ Linphone/core/chat/ChatCore.cpp
@@ -334,9 +334,6 @@ void ChatCore::setSelf(const QSharedPointer<ChatCore> 
 		});
 	});
 
-	mChatModelConnection->makeConnectToCore(&ChatCore::lEnableEphemeral, [this](bool enable) {
-		mChatModelConnection->invokeToModel([this, enable]() { mChatModel->enableEphemeral(enable); });
-	});
 	mChatModelConnection->makeConnectToModel(&ChatModel::ephemeralEnableChanged, [this](bool enable) {
 		mChatModelConnection->invokeToCore([this, enable]() {
 			if (mEphemeralEnabled != enable) {
