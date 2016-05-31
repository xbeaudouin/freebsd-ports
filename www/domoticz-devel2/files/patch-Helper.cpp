--- main/Helper.cpp.orig	2016-05-31 17:28:37.828644000 +0200
+++ main/Helper.cpp	2016-05-31 17:29:13.178423000 +0200
@@ -200,6 +200,11 @@
 				bUseDirectPath=true;
 				ret.push_back("/dev/" + fname);
 			}
+			else if (fname.find("cuaU")!=std::string::npos)
+			{
+				bUseDirectPath=true;
+				ret.push_back("/dev/" + fname);
+			}
 #endif
 #ifdef __APPLE__
 			else if (fname.find("cu.")!=std::string::npos)
