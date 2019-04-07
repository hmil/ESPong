
# PoC of a multiplayer pong game on the ESP8266

## Setup

```
git clone --recurse-submodules git@github.com:hmil/espong.git
cd espong
```

To build and flash the firmware, you'll either need Docker or a have the tools to build a nodemcu firmware.

Connect your nodemcu and boot it in flash mode. Then run:

```
# Build in Docker:
make flash

# Or, if you want to build natively
BUILD_FIRMWARE_IN_DOCKER=false make flash
```

To upload the lua files, simply run:

```
make upload
```

> ℹ️ The makefile remembers which files were uploaded to nodemcu and only uploads the files that have changed. If you connect a different nodemcu with the same serial port, then you'll want to clean the cache with
>
>     make clean
>
 ️

### Custom serial port

You can specify a custom serial port with the `PORT` environment variable.

For instance:
```
PORT=/dev/cu.usbmodem1234 make upload
```

