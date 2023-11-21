--- common/ldb_msg.c.orig	2023-03-29 13:42:11 UTC
+++ common/ldb_msg.c
@@ -459,6 +459,47 @@ int ldb_msg_element_add_value(TALLOC_CTX *mem_ctx,
 }
 
 /*
+ * add a value to a message element
+ */
+int ldb_msg_element_add_value(TALLOC_CTX *mem_ctx,
+			      struct ldb_message_element *el,
+			      const struct ldb_val *val)
+{
+	struct ldb_val *vals;
+
+	if (el->flags & LDB_FLAG_INTERNAL_SHARED_VALUES) {
+		/*
+		 * Another message is using this message element's values array,
+		 * so we don't want to make any modifications to the original
+		 * message, or potentially invalidate its own values by calling
+		 * talloc_realloc(). Make a copy instead.
+		 */
+		el->flags &= ~LDB_FLAG_INTERNAL_SHARED_VALUES;
+
+		vals = talloc_array(mem_ctx, struct ldb_val,
+				    el->num_values + 1);
+		if (vals == NULL) {
+			return LDB_ERR_OPERATIONS_ERROR;
+		}
+
+		if (el->values != NULL) {
+			memcpy(vals, el->values, el->num_values * sizeof(struct ldb_val));
+		}
+	} else {
+		vals = talloc_realloc(mem_ctx, el->values, struct ldb_val,
+				      el->num_values + 1);
+		if (vals == NULL) {
+			return LDB_ERR_OPERATIONS_ERROR;
+		}
+	}
+	el->values = vals;
+	el->values[el->num_values] = *val;
+	el->num_values++;
+
+	return LDB_SUCCESS;
+}
+
+/*
   add a value to a message
 */
 int ldb_msg_add_value(struct ldb_message *msg,
