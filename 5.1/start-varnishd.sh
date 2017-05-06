#!/bin/bash
set -e

exec bash -c \
	"exec varnishd -n /varnishfs -F \
	-a :${VARNISH_PORT:-6081} \
	-f ${VCL_CONFIG} \
	-s malloc,${VARNISH_MEMORY} \
	${VARNISHD_PARAMS}"
