--- uticom.c.orig	2006-03-01 07:58:51.000000000 +0100
+++ uticom.c	2017-08-16 14:18:37.530784000 +0200
@@ -97,7 +97,7 @@
 #include <sys/sysctl.h>
 #include <machine/bus.h>
 #include <dev/usb/usb.h>
-#include <dev/usb/usbcdc.h>
+#include <dev/usb/usb_cdc.h>
 
 #include <unistd.h>
 #include <sys/uio.h>
@@ -657,7 +657,7 @@
 	if (sc->sc_intr_pipe != NULL) {
 		usbd_abort_pipe(sc->sc_intr_pipe);
 		usbd_close_pipe(sc->sc_intr_pipe);
-		free(sc->sc_intr_buf, M_USBDEV);
+		free(sc->sc_intr_buf, M_USBDEV, sc->sc_isize);
 		sc->sc_intr_pipe = NULL;
 	}
 
@@ -1053,7 +1053,7 @@
 			printf("%s: close interrupt pipe failed: %s\n",
 			       USBDEVNAME(sc->sc_ucom.sc_dev),
 			       usbd_errstr(err));
-		free(sc->sc_intr_buf, M_USBDEV);
+		free(sc->sc_intr_buf, M_USBDEV,sc->sc_isize);
 		sc->sc_intr_pipe = NULL;
 	}
 
