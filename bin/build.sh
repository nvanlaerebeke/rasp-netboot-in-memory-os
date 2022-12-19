#!/bin/bash

ROOT="$(cd "$(dirname $(realpath "${BASH_SOURCE[0]}"))" >/dev/null 2>&1 && pwd)/../"

. $ROOT/bin/lib/functions.sh 

initramfs_build
rootfs_build

dist
