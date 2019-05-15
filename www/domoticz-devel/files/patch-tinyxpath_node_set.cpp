--- tinyxpath/node_set.cpp.orig	2019-05-15 10:50:49.000000000 +0200
+++ tinyxpath/node_set.cpp	2019-05-15 13:36:41.258566000 +0200
@@ -40,6 +40,16 @@
    u_nb_node = ns2 . u_nb_node;
    if (u_nb_node)
    {
+      if ( vpp_node_set != NULL )
+      {
+          delete[] vpp_node_set;
+      }
+      
+      if ( op_attrib != NULL )
+      {
+          delete[] op_attrib;
+      }
+      
       vpp_node_set = new const void * [u_nb_node];
       memcpy (vpp_node_set, ns2 . vpp_node_set, u_nb_node * sizeof (void *));
       op_attrib = new bool [u_nb_node];
