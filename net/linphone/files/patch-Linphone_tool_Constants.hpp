--- Linphone/tool/Constants.hpp.orig	2026-03-29 23:57:07 UTC
+++ Linphone/tool/Constants.hpp
@@ -203,11 +203,11 @@ class Constants : public QObject { (public)
 //--------------------------------------------------------------------------------
 //								CISCO
 //--------------------------------------------------------------------------------
-#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
+#if defined(Q_OS_LINUX) || defined(Q_OS_WIN) || defined(Q_OS_FREEBSD)
 	static constexpr char H264Description[] = "Provided by CISCO SYSTEM,INC";
 #endif // if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 	static constexpr char LibraryExtension[] = "so";
 	static constexpr char H264InstallName[] = "libopenh264.so";
 #ifdef Q_PROCESSOR_X86_64
