--- config/puma.rb.orig	2026-05-15 09:46:22 UTC
+++ config/puma.rb
@@ -19,6 +19,16 @@ pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }
 # Specifies the `pidfile` that Puma will use.
 pidfile ENV.fetch('PIDFILE') { 'tmp/pids/server.pid' }
 
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
 # Specifies the number of `workers` to boot in clustered mode.
 # Workers are forked web server processes. If using threads and workers together
 # the concurrency of the application would be max `threads` * `workers`.
