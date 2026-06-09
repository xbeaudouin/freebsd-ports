--- Linphone/model/chat/ChatModel.cpp.orig	2026-02-25 10:37:53 UTC
+++ Linphone/model/chat/ChatModel.cpp
@@ -147,15 +147,15 @@ void ChatModel::setMuted(bool muted) {
 	emit mutedChanged(muted);
 }
 
-void ChatModel::enableEphemeral(bool enable) {
-	mMonitor->enableEphemeral(enable);
-	emit ephemeralEnableChanged(enable);
-}
-
 void ChatModel::setEphemeralLifetime(int time) {
-	mMonitor->setEphemeralLifetime(time);
+	if (time != 0) {
+		mMonitor->activateEphemeral(time);
+	}
+	else {
+		mMonitor->deactivateEphemeral();
+	}
 	emit ephemeralLifetimeChanged(time);
-	enableEphemeral(time != 0);
+	emit ephemeralEnableChanged(time != 0);
 }
 
 void ChatModel::deleteHistory() {
