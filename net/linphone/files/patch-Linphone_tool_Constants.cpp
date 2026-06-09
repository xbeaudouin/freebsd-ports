--- Linphone/tool/Constants.cpp.orig	2026-03-29 23:55:25 UTC
+++ Linphone/tool/Constants.cpp
@@ -113,11 +113,11 @@ constexpr char Constants::DefaultOAuth2RemoteProvision
 constexpr char Constants::OAuth2Scope[];
 constexpr char Constants::DefaultOAuth2RemoteProvisioningHeader[];
 
-#if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
+#if defined(Q_OS_LINUX) || defined(Q_OS_WIN) || defined(Q_OS_FREEBSD)
 constexpr char Constants::H264Description[];
 #endif // if defined(Q_OS_LINUX) || defined(Q_OS_WIN)
 
-#ifdef Q_OS_LINUX
+#if defined(Q_OS_LINUX) || defined(Q_OS_FREEBSD)
 constexpr char Constants::LibraryExtension[];
 constexpr char Constants::H264InstallName[];
 #ifdef Q_PROCESSOR_X86_64
