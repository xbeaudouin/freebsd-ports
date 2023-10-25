--- hardware/plugins/PythonObjectEx.cpp.orig	2023-10-25 20:14:51.034831000 +0200
+++ hardware/plugins/PythonObjectEx.cpp	2023-10-25 20:15:09.616478000 +0200
@@ -640,7 +640,7 @@
 							sDescription.c_str(),
 							sColor.c_str(),
 							sOptionValue.c_str(),
-							TimeToString(nullptr, TF_DateTime));
+							TimeToString(nullptr, TF_DateTime).c_str());
 
 						if (!result.empty())
 						{
