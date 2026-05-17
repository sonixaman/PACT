SUMMARY = "PACT ZERO Beamformer Kernel Module"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=12f884d2ae1ff87c09e5b7ccc2c4ca7e"

inherit module

SRC_URI = "file://beamformer.c \
	   file://Makefile \ 
	   "

S = "${WORKDIR}"

KERNEL_MODULE_AUTOLOAD += "beamformer"

