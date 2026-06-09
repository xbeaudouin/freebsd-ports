--- Linphone/tool/Utils.cpp.orig	2026-03-29 23:54:00 UTC
+++ Linphone/tool/Utils.cpp
@@ -1550,7 +1550,7 @@ QList<QSharedPointer<DownloadablePayloadTypeCore>> Uti
 
 QList<QSharedPointer<DownloadablePayloadTypeCore>> Utils::getDownloadableVideoPayloadTypes() {
 	QList<QSharedPointer<DownloadablePayloadTypeCore>> payloadTypes;
-#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
+#if defined(Q_OS_LINUX) || defined(Q_OS_WIN) || defined(Q_OS_FREEBSD)
 	auto ciscoH264 = DownloadablePayloadTypeCore::create(PayloadTypeCore::Family::Video, "H264",
 	                                                     Constants::H264Description, Constants::PluginUrlH264,
 	                                                     Constants::H264InstallName, Constants::PluginH264Check);
@@ -1749,7 +1749,7 @@ void Utils::runCommandLine(const QString command) {
 	} else {
 		lWarning() << "Failed to start process. GetLastError() =" << (int)GetLastError();
 	}
-#elif defined(Q_OS_MACOS) || defined(Q_OS_LINUX)
+#elif defined(Q_OS_MACOS) || defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 	QProcess::startDetached("/bin/sh", {"-c", command});
 #else
 	lWarning() << "Unsupported OS!";
@@ -2224,4 +2224,4 @@ void Utils::forceCrash() {
 void Utils::forceCrash() {
 	lInfo() << "throwing segmentation fault for debug";
 	raise(SIGSEGV);
-}
\ No newline at end of file
+}
