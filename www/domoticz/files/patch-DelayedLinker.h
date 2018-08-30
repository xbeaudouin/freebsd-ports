--- hardware/plugins/DelayedLink.h.orig	2017-09-13 08:54:08.000000000 +0200
+++ hardware/plugins/DelayedLink.h	2017-09-13 17:46:10.983769000 +0200
@@ -136,6 +131,12 @@
 				if (!shared_lib_) FindLibrary("python3.6", true);
 				if (!shared_lib_) FindLibrary("python3.5", true);
 				if (!shared_lib_) FindLibrary("python3.4", true);
+#ifdef __FreeBSD__
+				if (!shared_lib_) FindLibrary("python3.7m", true);
+				if (!shared_lib_) FindLibrary("python3.6m", true);
+				if (!shared_lib_) FindLibrary("python3.5m", true);
+				if (!shared_lib_) FindLibrary("python3.4m", true);
+#endif /* FreeBSD */
 #endif
 				if (shared_lib_)
 				{
