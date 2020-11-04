# $FreeBSD: src/sys/modules/sound/driver/au88x0/Makefile,v 1.1 2003/06/01 11:58:46 des Exp $

.PATH: ${.CURDIR} /sys/pci

KMOD=	uticom
SRCS=	uticom.h utifw3410_p.h
SRCS+=	device_if.h bus_if.h pci_if.h vnode_if.h opt_uticom.h opt_usb.h usbdevs.h
SRCS+=	uticom.c
CFALGS+ = -I${WRKSRC}

.include <bsd.kmod.mk>
