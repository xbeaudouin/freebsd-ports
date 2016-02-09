--- getgit.cmake.orig	2016-02-08 10:35:03.000000000 +0100
+++ getgit.cmake	2016-02-08 23:43:31.000000000 +0100
@@ -1,59 +1,60 @@
 # the git.cmake module is part of the standard distribution
-find_package(Git)
-if(NOT GIT_FOUND)
-  MESSAGE(FATAL_ERROR "Git not found!.")
-endif()
-
-MACRO(Gitversion_GET_REVISION dir variable)
-  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} rev-list HEAD --count
-    OUTPUT_VARIABLE ${variable}
-    OUTPUT_STRIP_TRAILING_WHITESPACE)
-ENDMACRO(Gitversion_GET_REVISION)
-
-MACRO(Gitversion_GET_HASH dir variable)
-  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
-    OUTPUT_VARIABLE ${variable}
-    OUTPUT_STRIP_TRAILING_WHITESPACE)
-ENDMACRO(Gitversion_GET_HASH)
-
-MACRO(Gitversion_GET_DATE dir variable)
-  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} show -s --format=%ct
-    OUTPUT_VARIABLE ${variable}
-    OUTPUT_STRIP_TRAILING_WHITESPACE)
-ENDMACRO(Gitversion_GET_DATE)
-
-MACRO(Gitversion_CHECK_DIRTY dir variable)
-  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} diff-index -m --name-only HEAD
-    OUTPUT_VARIABLE ${variable}
-    OUTPUT_STRIP_TRAILING_WHITESPACE)
-ENDMACRO(Gitversion_CHECK_DIRTY)
-
-Gitversion_GET_REVISION(. ProjectRevision)
-IF(NOT ProjectRevision)
-  MESSAGE(STATUS "Failed to get ProjectRevision from git, set it to 0")
-  set (ProjectRevision 0)
-ELSE(NOT ProjectRevision)
-  MATH(EXPR ProjectRevision "${ProjectRevision}+2107")
-ENDIF(NOT ProjectRevision)
-Gitversion_GET_HASH(. ProjectHash)
-IF(NOT ProjectHash)
-  MESSAGE(STATUS "Failed to get ProjectHash from git, set it to 0")
-  set (ProjectHash 0)
-ENDIF(NOT ProjectHash)
-Gitversion_GET_DATE(. ProjectDate)
-IF(NOT ProjectDate)
-  MESSAGE(STATUS "Failed to get ProjectDate from git, set it to 0")
-  set (ProjectDate 0)
-ENDIF(NOT ProjectDate)
-Gitversion_CHECK_DIRTY(. ProjectDirty)
-IF(ProjectDirty)
-  MESSAGE(STATUS "domoticz has been modified locally: add \"-modified\" to hash")
-  set (ProjectHash "${ProjectHash}-modified")
-ENDIF(ProjectDirty)
-
-# write a file with the APPVERSION define
-file(WRITE appversion.h.txt "#define APPVERSION ${ProjectRevision}\n#define APPHASH \"${ProjectHash}\"\n#define APPDATE ${ProjectDate}\n")
+#find_package(Git)
+#if(NOT GIT_FOUND)
+#  MESSAGE(FATAL_ERROR "Git not found!.")
+#endif()
+#
+#MACRO(Gitversion_GET_REVISION dir variable)
+#  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} rev-list HEAD --count
+#    OUTPUT_VARIABLE ${variable}
+#    OUTPUT_STRIP_TRAILING_WHITESPACE)
+#ENDMACRO(Gitversion_GET_REVISION)
+#
+#MACRO(Gitversion_GET_HASH dir variable)
+#  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} rev-parse --short HEAD
+#    OUTPUT_VARIABLE ${variable}
+#    OUTPUT_STRIP_TRAILING_WHITESPACE)
+#ENDMACRO(Gitversion_GET_HASH)
+#
+#MACRO(Gitversion_GET_DATE dir variable)
+#  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} show -s --format=%ct
+#    OUTPUT_VARIABLE ${variable}
+#    OUTPUT_STRIP_TRAILING_WHITESPACE)
+#ENDMACRO(Gitversion_GET_DATE)
+#
+#MACRO(Gitversion_CHECK_DIRTY dir variable)
+#  EXECUTE_PROCESS(COMMAND ${GIT_EXECUTABLE} diff-index -m --name-only HEAD
+#    OUTPUT_VARIABLE ${variable}
+#    OUTPUT_STRIP_TRAILING_WHITESPACE)
+#ENDMACRO(Gitversion_CHECK_DIRTY)
+#
+#Gitversion_GET_REVISION(. ProjectRevision)
+#IF(NOT ProjectRevision)
+#  MESSAGE(STATUS "Failed to get ProjectRevision from git, set it to 0")
+#  set (ProjectRevision 0)
+#ELSE(NOT ProjectRevision)
+#  MATH(EXPR ProjectRevision "${ProjectRevision}+2107")
+#ENDIF(NOT ProjectRevision)
+#Gitversion_GET_HASH(. ProjectHash)
+#IF(NOT ProjectHash)
+#  MESSAGE(STATUS "Failed to get ProjectHash from git, set it to 0")
+#  set (ProjectHash 0)
+#ENDIF(NOT ProjectHash)
+#Gitversion_GET_DATE(. ProjectDate)
+#IF(NOT ProjectDate)
+#  MESSAGE(STATUS "Failed to get ProjectDate from git, set it to 0")
+#  set (ProjectDate 0)
+#ENDIF(NOT ProjectDate)
+#Gitversion_CHECK_DIRTY(. ProjectDirty)
+#IF(ProjectDirty)
+#  MESSAGE(STATUS "domoticz has been modified locally: add \"-modified\" to hash")
+#  set (ProjectHash "${ProjectHash}-modified")
+#ENDIF(ProjectDirty)
+#
+## write a file with the APPVERSION define
+#file(WRITE appversion.h.txt "#define APPVERSION ${ProjectRevision}\n#define APPHASH \"${ProjectHash}\"\n#define APPDATE ${ProjectDate}\n")
 
+set (ProjectDate 0)
 # if ProjectDate is 0, create appversion.h.txt from a copy of appversion.default
 IF(NOT ProjectDate AND EXISTS appversion.default)
   MESSAGE(STATUS "ProjectDate is 0 and appversion.default exists, copy it")
