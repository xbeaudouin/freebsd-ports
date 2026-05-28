--- cmake/Modules/FindBCToolbox.cmake.orig	2026-02-25 10:37:53 UTC
+++ cmake/Modules/FindBCToolbox.cmake
@@ -33,8 +33,8 @@ if(NOT TARGET bctoolbox)
 if(NOT TARGET bctoolbox)
     set(EXPORT_PATH ${LINPHONE_OUTPUT_DIR})
     include(GNUInstallDirs)
-    set(BCToolbox_CMAKE_DIR ${EXPORT_PATH}/${CMAKE_INSTALL_DATADIR}/bctoolbox/cmake)
-    include(${BCToolbox_CMAKE_DIR}/bctoolboxTargets.cmake)
+    set(BCToolbox_CMAKE_DIR ${EXPORT_PATH}/${CMAKE_INSTALL_DATADIR}/BCToolbox/cmake)
+    include(${BCToolbox_CMAKE_DIR}/BCToolboxConfig.cmake)
 endif()
 
 set(_BCToolbox_REQUIRED_VARS BCToolbox_TARGET BCToolbox_CMAKE_DIR BCToolbox_CMAKE_UTILS)
