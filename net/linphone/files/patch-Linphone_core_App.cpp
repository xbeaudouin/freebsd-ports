--- Linphone/core/App.cpp.orig	2026-03-29 23:48:22 UTC
+++ Linphone/core/App.cpp
@@ -123,7 +123,7 @@ DEFINE_ABSTRACT_OBJECT(App)
 
 DEFINE_ABSTRACT_OBJECT(App)
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 const QString AutoStartDirectory(QDir::homePath().append(QStringLiteral("/.config/autostart/")));
 const QString ApplicationsDirectory(QDir::homePath().append(QStringLiteral("/.local/share/applications/")));
 const QString IconsDirectory(QDir::homePath().append(QStringLiteral("/.local/share/icons/hicolor/scalable/apps/")));
@@ -138,7 +138,7 @@ const QString
 //		Autostart
 // -----------------------------------------------------------------------------
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 bool App::autoStartEnabled() {
 	const QString confPath(AutoStartDirectory + EXECUTABLE_NAME ".desktop");
 	QFile file(confPath);
@@ -227,7 +227,7 @@ bool App::autoStartEnabled() {
 }
 #endif // ifdef Q_OS_LINUX
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 
 void App::setAutoStart(bool enabled) {
 	if (enabled == mAutoStart) return;
@@ -335,7 +335,7 @@ App::App(int &argc, char *argv[])
 	mEventCountNotifier = new EventCountNotifier(this);
 	mDateUpdateTimer.start();
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 	exportDesktopFile();
 #endif
 }
@@ -1028,7 +1028,7 @@ void App::initFonts() {
 			allFamilies << QFontDatabase::applicationFontFamilies(id);
 		}
 	}
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 	QDirIterator itFonts(":/linux/font/", QDirIterator::Subdirectories);
 	while (itFonts.hasNext()) {
 		QString ttf = itFonts.next();
@@ -1481,7 +1481,7 @@ void App::onAuthenticationRequested(const std::shared_
 	});
 }
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 QString App::getApplicationPath() const {
 	const QString binPath(QCoreApplication::applicationFilePath());
 
