--- main/Helper.cpp.orig	2016-05-31 16:22:53.656126000 +0200
+++ main/Helper.cpp	2016-05-31 16:23:35.313126000 +0200
@@ -200,6 +200,12 @@
 				bUseDirectPath=true;
 				ret.push_back("/dev/" + fname);
 			}
+			else if (fname.find("cuaU")!=std::string::npos)
+			{
+				bUseDirectPath=true;
+				ret.push_back("/dev/" + fname);
+			}
+#endif
 #endif
 #ifdef __APPLE__
 			else if (fname.find("cu.")!=std::string::npos)
