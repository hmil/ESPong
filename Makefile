# Path to nodemcu-uploader
NODEMCU-UPLOADER=./nodemcu-uploader/nodemcu-uploader.py
# Serial port. This will probably be different on your machine
PORT?=/dev/cu.SLAB_USBtoUART
# Serial baudrate
SPEED=115200
ifndef BUILD_FIRMWARE_IN_DOCKER
	override BUILD_FIRMWARE_IN_DOCKER=true
endif

FIRMWARE=build/nodemcu-firmware.bin

NODEMCU-COMMAND=python $(NODEMCU-UPLOADER) -b $(SPEED) --start_baud $(SPEED) -p $(PORT)
SUFFIX=$(subst /,_,$(PORT))

LUA_FILES := $(wildcard src/*.lua)
LUA_BUILD_FILES := $(LUA_FILES:src/%.lua=build/%.$(SUFFIX))

.PHONY: upload
upload: $(LUA_BUILD_FILES)

build/%.$(SUFFIX): src/%.lua
	$(NODEMCU-COMMAND) node restart
	$(NODEMCU-COMMAND) upload --compile "$<:$(patsubst src/%,%,$<)"
	mkdir -p build
	touch $@

.PHONY: clean
clean:
	rm -rf build/*.$(SUFFIX)

.PHONY: clean-device
clean-device: clean
	$(NODEMCU-COMMAND) file format

.PHONY: list
list:
	$(NODEMCU-COMMAND) file list

.PHONY: restart
restart:
	$(NODEMCU-COMMAND) node restart


$(FIRMWARE): user_modules.h nodemcu-firmware/Makefile
	BUILD_FIRMWARE_IN_DOCKER=$(BUILD_FIRMWARE_IN_DOCKER) $(SHELL) build-firmware.sh

esptool.py:
	curl -o esptool.py https://raw.githubusercontent.com/espressif/esptool/master/esptool.py

.PHONY: flash
flash: $(FIRMWARE) esptool.py
	# Erase flash to avoid inconsistent state:
	python esptool.py --port $(PORT) erase_flash
	# Upload firmware
	python esptool.py --port $(PORT) write_flash -fm dio 0x00000 $(FIRMWARE)
