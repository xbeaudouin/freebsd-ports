--- Linphone/core/App.hpp.orig	2026-03-30 00:16:30 UTC
+++ Linphone/core/App.hpp
@@ -202,7 +202,7 @@ class App : public SingleApplication, public AbstractO
 	float getScreenRatio() const;
 	Q_INVOKABLE void setScreenRatio(float ratio);
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined (Q_OS_FREEBSD)
 	Q_INVOKABLE void exportDesktopFile();
 
 	QString getApplicationPath() const;
