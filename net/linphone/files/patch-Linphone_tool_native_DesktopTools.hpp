--- Linphone/tool/native/DesktopTools.hpp.orig	2026-02-25 10:37:53 UTC
+++ Linphone/tool/native/DesktopTools.hpp
@@ -23,7 +23,7 @@
 
 #include <QtGlobal>
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 #include "DesktopToolsLinux.hpp"
 #elif defined(Q_OS_WIN)
 #include "DesktopToolsWindows.hpp"
