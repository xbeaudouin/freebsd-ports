--- Linphone/tool/crash_reporter/CrashReporter.cpp.orig	2026-03-29 23:58:53 UTC
+++ Linphone/tool/crash_reporter/CrashReporter.cpp
@@ -69,7 +69,7 @@ bool CrashReporter::run() {
 
 	// Attachments to be uploaded alongside the crash - default bundle size limit is 20MB
 	base::FilePath attachment(Utils::getNativeString(Paths::getCrashpadAttachmentsPath()));
-#if defined(Q_OS_WINDOWS) || defined(Q_OS_LINUX)
+#if defined(Q_OS_WINDOWS) || defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 	// Crashpad hasn't implemented attachments on OS X yet
 	mAttachments.push_back(attachment);
 #endif
