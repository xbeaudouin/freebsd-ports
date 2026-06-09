--- Linphone/model/tool/ToolModel.cpp.orig	2026-02-25 10:37:53 UTC
+++ Linphone/model/tool/ToolModel.cpp
@@ -561,7 +561,7 @@ void ToolModel::loadDownloadedCodecs() {
 // reloadMsPlugins modifies plugin path for the factory)
 void ToolModel::loadDownloadedCodecs() {
 	mustBeInLinphoneThread(sLog().arg(Q_FUNC_INFO));
-#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
+#if defined(Q_OS_LINUX) || defined(Q_OS_WIN) || defined(Q_OS_FREEBSD)
 	lInfo() << QStringLiteral("[ToolModel] Loading downloaded codecs in folder %1…").arg(Paths::getCodecsDirPath());
 	QDirIterator it(Paths::getCodecsDirPath());
 	while (it.hasNext()) {
@@ -587,7 +587,7 @@ void ToolModel::updateCodecs() {
 
 void ToolModel::updateCodecs() {
 	mustBeInLinphoneThread(sLog().arg(Q_FUNC_INFO));
-#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
+#if defined(Q_OS_LINUX) || defined(Q_OS_WIN) || defined(Q_OS_FREEBSD)
 	static const QString codecSuffix = QStringLiteral(".%1").arg(Constants::LibraryExtension);
 
 	QDirIterator it(Paths::getCodecsDirPath());
@@ -658,7 +658,7 @@ ToolModel::getChatRoomParams(std::shared_ptr<linphone:
 		qWarning() << "failed to get chat params from conference params, return";
 		return nullptr;
 	}
-	chatParams->setEphemeralLifetime(0);
+	chatParams->deactivateEphemeral();
 	auto accountParams = account->getParams();
 	auto sameDomain = remoteAddress && remoteAddress->getDomain() == SettingsModel::getInstance()->getDefaultDomain() &&
 	                  remoteAddress->getDomain() == accountParams->getDomain();
@@ -778,7 +778,7 @@ ToolModel::createGroupChatRoom(QString subject, std::l
 		qWarning() << "failed to get chat params from conference params, return";
 		return nullptr;
 	}
-	chatParams->setEphemeralLifetime(0);
+	chatParams->deactivateEphemeral();
 	chatParams->setBackend(linphone::ChatRoom::Backend::FlexisipChat);
 
 	auto accountParams = account->getParams();
