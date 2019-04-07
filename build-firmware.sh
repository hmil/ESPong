#!/bin/bash -xe

cp user_modules.h nodemcu-firmware/app/include/user_modules.h
rm nodemcu-firmware/bin/*

if $BUILD_FIRMWARE_IN_DOCKER; then
    docker run --rm -ti -v "$(pwd)/nodemcu-firmware:/opt/nodemcu-firmware" -v "$(pwd)/.git:/opt/.git" marcelstoer/nodemcu-build build
else
    make
fi

mkdir -p build/
cp nodemcu-firmware/bin/nodemcu_*.bin build/nodemcu-firmware.bin
