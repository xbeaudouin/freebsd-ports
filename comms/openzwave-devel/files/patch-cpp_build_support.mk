--- cpp/build/support.mk.orig	2016-06-06 16:02:21.113321000 +0200
+++ cpp/build/support.mk	2016-06-06 16:02:42.530037000 +0200
@@ -31,8 +31,8 @@
 else
 GITVERSION	:= $(shell $(GIT) --git-dir $(top_srcdir)/.git describe --long --tags --dirty 2>/dev/null | sed s/^v//)
 ifeq ($(GITVERSION),)
-GITVERSION	:= $(VERSION_MAJ).$(VERSION_MIN).-1
-VERSION_REV	:= 0
+GITVERSION	:= $(VERSION_MAJ).$(VERSION_MIN).$(VERSION_REV)
+#VERSION_REV	:= 0
 else
 VERSION_REV 	?= $(shell echo $(GITVERSION) | awk '{split($$0,a,"-"); print a[2]}')
 endif
