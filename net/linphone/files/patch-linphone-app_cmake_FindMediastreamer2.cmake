--- cmake/Modules/FindMediastreamer2.cmake.orig	2026-02-25 10:37:53 UTC
+++ cmake/Modules/FindMediastreamer2.cmake
@@ -29,7 +29,7 @@ if(NOT TARGET mediastreamer2)
 if(NOT TARGET mediastreamer2)
     set(EXPORT_PATH ${LINPHONE_OUTPUT_DIR})
     include(GNUInstallDirs)
-    include(${EXPORT_PATH}/${CMAKE_INSTALL_DATADIR}/Mediastreamer2/cmake/Mediastreamer2Targets.cmake)
+    include(${EXPORT_PATH}/${CMAKE_INSTALL_DATADIR}/Mediastreamer2/cmake/Mediastreamer2Config.cmake)
 endif()
 
 set(_Mediastreamer2_REQUIRED_VARS Mediastreamer2_TARGET Mediastreamer2_PLUGINS_DIR)
@@ -40,10 +40,10 @@ endif()
 	get_target_property(Mediastreamer2_PLUGINS_DIR ${Mediastreamer2_TARGET} MS2_PLUGINS_DIR)
 endif()
 
-include(FindPackageHandleStandardArgs)
-find_package_handle_standard_args(Mediastreamer2
-	REQUIRED_VARS ${_Mediastreamer2_REQUIRED_VARS}
-	HANDLE_COMPONENTS
-)
+# include(FindPackageHandleStandardArgs)
+# find_package_handle_standard_args(Mediastreamer2
+#	REQUIRED_VARS ${_Mediastreamer2_REQUIRED_VARS}
+#	HANDLE_COMPONENTS
+#)
 mark_as_advanced(${_Mediastreamer2_CACHE_VARS})
 
