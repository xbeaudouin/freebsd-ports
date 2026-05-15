--- config/puma.rb.orig
+++ config/puma.rb
@@ -1,5 +1,13 @@
 # frozen_string_literal: true
 
+# FreeBSD port: override log paths to the system log directory.
+# CHATWOOT_LOGDIR is exported by the rc.d script; fall back to the
+# application directory for non-rc.d invocations.
+_logdir = ENV.fetch('CHATWOOT_LOGDIR', File.expand_path('../log', __dir__))
+stdout_redirect(
+  File.join(_logdir, 'web.log'),
+  File.join(_logdir, 'web.log'),
+  true  # append
+)
+
 # Puma configuration file
 workers ENV.fetch('WEB_CONCURRENCY', 2).to_i
