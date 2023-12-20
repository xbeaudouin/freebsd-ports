--- hardware/plugins/DelayedLink.h.orig	2023-12-05 10:33:03.068932000 +0100
+++ hardware/plugins/DelayedLink.h	2023-12-05 10:38:10.694601000 +0100
@@ -6,6 +6,7 @@
 #	pragma GCC diagnostic ignored "-Wwrite-strings"
 #endif
 
+/* XXX: Why ? */
 #ifdef WITH_THREAD
 #    undefine WITH_THREAD
 #endif
@@ -149,7 +150,9 @@
 		DECLARE_PYTHON_SYMBOL(PyObject*, Py_CompileString, const char* COMMA const char* COMMA int);
 		DECLARE_PYTHON_SYMBOL(PyObject*, PyEval_EvalCode, PyObject* COMMA PyObject* COMMA PyObject*);
 		DECLARE_PYTHON_SYMBOL(long, PyType_GetFlags, PyTypeObject*);
+#if PY_VERSION_HEX < 0x03090000
 		DECLARE_PYTHON_SYMBOL(void, _Py_Dealloc, PyObject*);
+#endif
 
 		SharedLibraryProxy() {
 			Py_None = nullptr;
@@ -288,7 +291,9 @@
 					RESOLVE_PYTHON_SYMBOL(Py_CompileString);
 					RESOLVE_PYTHON_SYMBOL(PyEval_EvalCode);
 					RESOLVE_PYTHON_SYMBOL(PyType_GetFlags);
+#if PY_VERSION_HEX < 0x03090000
 					RESOLVE_PYTHON_SYMBOL(_Py_Dealloc);
+#endif
 				}
 			}
 		};
@@ -527,6 +532,13 @@
 #	endif
 #endif
 
+/* Python >= 3.9 has removed Py_Dealloc */
+#if PY_VERSION_HEX >= 0x03090000
+# ifndef _Py_Dealloc
+#  define _Py_Dealloc
+# endif
+#endif 
+
 #if PY_VERSION_HEX >= 0x030800f0
 static inline void py3__Py_INCREF(PyObject* op)
 {
@@ -564,10 +576,12 @@
 		}
 #endif
 	}
+#if PY_VERSION_HEX <= 0x03090000
 	else
 	{
 		_Py_Dealloc(op);
 	}
+#endif
 }
 
 #undef Py_DECREF
