--- Linphone/model/chat/ChatModel.hpp.orig	2026-03-29 12:58:53 UTC
+++ Linphone/model/chat/ChatModel.hpp
@@ -79,7 +79,6 @@ class ChatModel : public ::Listener<linphone::ChatRoom
 	void compose();
 	linphone::ChatRoom::State getState() const;
 	void setMuted(bool muted);
-	void enableEphemeral(bool enable);
 	void setEphemeralLifetime(int time);
 	void setSubject(QString subject) const;
 	void removeParticipantAtIndex(int index) const;
