--- hardware/EcoDevices.cpp.orig	2022-12-02 09:05:02.507549000 +0100
+++ hardware/EcoDevices.cpp	2022-12-02 09:05:27.061911000 +0100
@@ -169,7 +169,7 @@
 	teleinfo.BBRHCJB = i_xpath_int(XMLdoc.RootElement(), "/response/BBRHCJB/text()");
 	teleinfo.BBRHPJB = i_xpath_int(XMLdoc.RootElement(), "/response/BBRHPJB/text()");
 	teleinfo.BBRHCJW = i_xpath_int(XMLdoc.RootElement(), "/response/BBRHCJW/text()");
-	teleinfo.BBRHPJW = i_xpath_int(XMLdoc.RootElement(), "/response/BBRHPJB/text()");
+	teleinfo.BBRHPJW = i_xpath_int(XMLdoc.RootElement(), "/response/BBRHPJW/text()");
 	teleinfo.BBRHCJR = i_xpath_int(XMLdoc.RootElement(), "/response/BBRHCJR/text()");
 	teleinfo.BBRHPJR = i_xpath_int(XMLdoc.RootElement(), "/response/BBRHPJR/text()");
 	teleinfo.PEJP = i_xpath_int(XMLdoc.RootElement(), "/response/PEJP/text()");
