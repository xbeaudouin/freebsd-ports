--- cmake/Modules/FindLibLinphone.cmake.orig	2026-03-29 11:30:09 UTC
+++ cmake/Modules/FindLibLinphone.cmake
@@ -27,7 +27,7 @@ if(NOT TARGET liblinphone)
 if(NOT TARGET liblinphone)
     set(EXPORT_PATH ${LINPHONE_OUTPUT_DIR})
     include(GNUInstallDirs)
-    include(${EXPORT_PATH}/${CMAKE_INSTALL_DATADIR}/linphone/cmake/linphoneTargets.cmake)
+    include(${EXPORT_PATH}/${CMAKE_INSTALL_DATADIR}/LibLinphone/cmake/LibLinphoneConfig.cmake)
 endif()
 
 set(_LibLinphone_REQUIRED_VARS LibLinphone_TARGET LibLinphone_PLUGINS_DIR)
@@ -38,9 +38,9 @@ endif()
 	get_target_property(LibLinphone_PLUGINS_DIR ${LibLinphone_TARGET} LIBLINPHONE_PLUGINS_DIR)
 endif()
 
-include(FindPackageHandleStandardArgs)
-find_package_handle_standard_args(LibLinphone
-	REQUIRED_VARS ${_LibLinphone_REQUIRED_VARS}
-	HANDLE_COMPONENTS
-)
+#include(FindPackageHandleStandardArgs)
+#find_package_handle_standard_args(LibLinphone
+#	REQUIRED_VARS ${_LibLinphone_REQUIRED_VARS}
+#	HANDLE_COMPONENTS
+#)
 mark_as_advanced(${_LibLinphone_CACHE_VARS})
