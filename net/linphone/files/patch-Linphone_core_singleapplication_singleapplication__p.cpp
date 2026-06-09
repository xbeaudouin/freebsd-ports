--- Linphone/core/singleapplication/singleapplication_p.cpp.orig	2026-03-29 23:47:21 UTC
+++ Linphone/core/singleapplication/singleapplication_p.cpp
@@ -143,7 +143,7 @@ void SingleApplicationPrivate::genBlockServerName() {
 	if (!(options & SingleApplication::Mode::ExcludeAppPath)) {
 #if defined(Q_OS_WIN)
 		appData.addData(SingleApplication::app_t::applicationFilePath().toLower().toUtf8());
-#elif defined(Q_OS_LINUX)
+#elif defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 		// If the application is running as an AppImage then the APPIMAGE env var should be used
 		// instead of applicationPath() as each instance is launched with its own executable path
 		const QByteArray appImagePath = qgetenv("APPIMAGE");
