--- config.go.orig	2022-10-05 11:40:37 UTC
+++ config.go
@@ -128,6 +128,7 @@ func LoadConfig(path string, isFile bool) error {
 	} else {
 		viper.SetConfigName("config")
 		if path == "" {
+			viper.AddConfigPath("/usr/local/etc/headscale/")
 			viper.AddConfigPath("/etc/headscale/")
 			viper.AddConfigPath("$HOME/.headscale")
 			viper.AddConfigPath(".")
