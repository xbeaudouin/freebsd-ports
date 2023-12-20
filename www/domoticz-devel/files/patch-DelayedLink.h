--- hardware/plugins/DelayedLink.h.orig	2023-12-20 10:16:58.680057000 +0100
+++ hardware/plugins/DelayedLink.h	2023-12-20 10:18:24.872947000 +0100
@@ -511,18 +511,14 @@
 #define	Py_CompileString		pythonLib->Py_CompileString
 #define	PyEval_EvalCode			pythonLib->PyEval_EvalCode
 #define	PyType_GetFlags			pythonLib->PyType_GetFlags
-#ifdef WIN32  
-#	define	_Py_Dealloc				pythonLib->_Py_Dealloc		// Builds against a low Python version
-#elif PY_VERSION_HEX < 0x03090000
-#	define	_Py_Dealloc				pythonLib->_Py_Dealloc
-#else
+#define	_Py_Dealloc			pythonLib->_Py_Dealloc
+#if PY_VERSION_HEX >= 0x03090000
 #	ifndef _Py_DEC_REFTOTAL
 	/* _Py_DEC_REFTOTAL macro has been removed from Python 3.9 by: https://github.com/python/cpython/commit/49932fec62c616ec88da52642339d83ae719e924 */
 #		ifdef Py_REF_DEBUG
 #			define _Py_DEC_REFTOTAL _Py_RefTotal--
 #		else
 #			define _Py_DEC_REFTOTAL
-#			define _Py_Dealloc
 #		endif
 #	endif
 #endif
