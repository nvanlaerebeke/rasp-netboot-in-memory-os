#!/bin/bash

ROOT="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)/../"

if [ -f "$ROOT/env" ];
then
    . $ROOT/env
fi

. $ROOT/bin/lib/functions.sh 

build_initramfs
build_rootfs

dist
