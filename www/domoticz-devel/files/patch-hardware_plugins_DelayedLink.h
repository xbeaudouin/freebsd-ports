--- hardware/plugins/DelayedLink.h.orig	2022-03-07 11:17:17.838832000 +0100
+++ hardware/plugins/DelayedLink.h	2022-03-07 11:18:05.606702000 +0100
@@ -171,6 +171,9 @@
 				if (!shared_lib_) FindLibrary("python3.5", true);
 				if (!shared_lib_) FindLibrary("python3.4", true);
 #ifdef __FreeBSD__
+				if (!shared_lib_) FindLibrary("python3.10m", true);
+				if (!shared_lib_) FindLibrary("python3.9m", true);
+				if (!shared_lib_) FindLibrary("python3.8m", true);
 				if (!shared_lib_) FindLibrary("python3.7m", true);
 				if (!shared_lib_) FindLibrary("python3.6m", true);
 				if (!shared_lib_) FindLibrary("python3.5m", true);
