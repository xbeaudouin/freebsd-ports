--- getgit.cmake.orig	2016-02-08 18:06:47.574045000 +0100
+++ getgit.cmake	2016-02-08 18:07:04.517380000 +0100
@@ -1,5 +1,5 @@
 # the git.cmake module is part of the standard distribution
-find_package(Git)
+find_package(NoGitNo)
 if(NOT GIT_FOUND)
   MESSAGE(FATAL_ERROR "Git not found!.")
 endif()
