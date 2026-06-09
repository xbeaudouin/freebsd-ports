--- Linphone/model/conference/ConferenceInfoModel.cpp.orig	2026-02-25 10:37:53 UTC
+++ Linphone/model/conference/ConferenceInfoModel.cpp
@@ -73,7 +73,7 @@ void ConferenceInfoModel::setConferenceScheduler(const
 					                                                  // secured chatroom
 					        auto chatParams = params->getChatParams();
 					        if (!chatParams) return;
-					        chatParams->setEphemeralLifetime(0);
+					        chatParams->deactivateEphemeral();
 					        chatParams->setBackend(linphone::ChatRoom::Backend::FlexisipChat);
 					        params->setSecurityLevel(linphone::Conference::SecurityLevel::EndToEnd);
 					        mConferenceSchedulerModel->getMonitor()->sendInvitations(params);
