--- Linphone/core/chat/ChatCore.hpp.orig	2026-03-29 12:53:20 UTC
+++ Linphone/core/chat/ChatCore.hpp
@@ -60,7 +60,7 @@ class ChatCore : public QObject, public AbstractObject
 	Q_PROPERTY(bool isSecured READ isSecured WRITE setIsSecured NOTIFY isSecuredChanged)
 	Q_PROPERTY(bool isBasic MEMBER mIsBasic CONSTANT)
 	Q_PROPERTY(QString sendingText READ getSendingText WRITE setSendingText NOTIFY sendingTextChanged)
-	Q_PROPERTY(bool ephemeralEnabled READ isEphemeralEnabled WRITE lEnableEphemeral NOTIFY ephemeralEnabledChanged)
+	Q_PROPERTY(bool ephemeralEnabled READ isEphemeralEnabled NOTIFY ephemeralEnabledChanged)
 	Q_PROPERTY(
 	    int ephemeralLifetime READ getEphemeralLifetime WRITE lSetEphemeralLifetime NOTIFY ephemeralLifetimeChanged)
 	Q_PROPERTY(bool muted READ isMuted WRITE lSetMuted NOTIFY mutedChanged)
@@ -190,7 +190,6 @@ signals:
 	void lCompose();
 	void lLeave();
 	void lSetMuted(bool muted);
-	void lEnableEphemeral(bool enable);
 	void lSetEphemeralLifetime(int time);
 	void lSetSubject(QString subject);
 	void lRemoveParticipantAtIndex(int index);
