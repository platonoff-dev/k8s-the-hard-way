#!/bin/bash


STREAM="stable"

podman run \
	--pull=always \
	--rm -v $(pwd)/runtime:/data \
	-w /data \
    	quay.io/coreos/coreos-installer:release download -s "${STREAM}" -p qemu -f qcow2.xz --decompress
