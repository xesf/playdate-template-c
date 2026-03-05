# Template - Playdate Game Makefile
# Usage:
#   make              - Configure + build for simulator
#   make device       - Configure + build for device
#   make run          - Build and launch in simulator
#   make deploy       - Build and deploy to connected device
#   make demo         - Build demo for simulator
#   make demo-device  - Build demo for device
#   make demo-run     - Build demo and launch in simulator
#   make clean        - Remove all build directories
#   make release      - Build device + package release zip
#   make release-demo - Build demo device + package release zip
#   make audio-convert         - Convert all sounds to Playdate format (mono 16-bit PCM)
#   make audio-normalize       - Analyze loudness of all sounds
#   make audio-normalize TARGET_DB=-16 - Normalize all sounds to target LUFS
#   make audio-normalize TARGET_DB=-16 DRY=1 - Dry run normalization

SDK_PATH := $(PLAYDATE_SDK_PATH)
SIMULATOR := "$(SDK_PATH)/bin/Playdate Simulator.app"
PDC := $(SDK_PATH)/bin/pdc
PDUTIL := $(SDK_PATH)/bin/pdutil
GAME_NAME := template
PDX := $(GAME_NAME).pdx
PLAYDATE_VOLUME := /Volumes/PLAYDATE
GAMES_DIR := $(PLAYDATE_VOLUME)/Games

# ─── Simulator ───────────────────────────────────────────────────────

.PHONY: configure build run

configure:
	cmake -B build -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=clang

build: configure
	cmake --build build

run: build
	open $(SIMULATOR) --args $(CURDIR)/$(PDX)

# ─── Device ──────────────────────────────────────────────────────────

.PHONY: configure-device device deploy

configure-device:
	cmake -B build-device \
		-DCMAKE_BUILD_TYPE=Release \
		-DTOOLCHAIN=armgcc \
		--toolchain=$(SDK_PATH)/C_API/buildsupport/arm.cmake

device: configure-device
	cmake --build build-device

deploy: device
	@DEVICE=$$(ls /dev/cu.usbmodem* 2>/dev/null | head -1); \
	if [ -z "$$DEVICE" ]; then \
		echo "Error: No Playdate device found. Connect via USB and unlock the device."; \
		exit 1; \
	fi; \
	echo "Found Playdate at $$DEVICE"; \
	echo "Mounting data disk..."; \
	$(PDUTIL) "$$DEVICE" datadisk; \
	echo "Waiting for device to reboot into data disk mode..."; \
	while [ -e "$$DEVICE" ]; do sleep 0.1; done; \
	echo "Waiting for volume to mount..."; \
	while [ ! -d "$(PLAYDATE_VOLUME)/Games" ]; do sleep 0.1; done; \
	echo "Syncing $(PDX) to device..."; \
	mkdir -p "$(GAMES_DIR)/$(PDX)"; \
	rsync -urtv --delete --exclude '.*' $(CURDIR)/$(PDX)/ "$(GAMES_DIR)/$(PDX)/"; \
	echo "Ejecting..."; \
	diskutil eject "$(PLAYDATE_VOLUME)"; \
	echo "Waiting for device to reconnect..."; \
	while [ -z "$$(ls /dev/cu.usbmodem* 2>/dev/null)" ]; do sleep 0.1; done; \
	sleep 1; \
	DEVICE=$$(ls /dev/cu.usbmodem* 2>/dev/null | head -1); \
	echo "Running $(PDX) on device..."; \
	$(PDUTIL) "$$DEVICE" run /Games/$(PDX)

# ─── Simulator (demo) ───────────────────────────────────────────────

.PHONY: configure-demo demo demo-run

configure-demo:
	cmake -B build-demo \
		-DCMAKE_BUILD_TYPE=Debug \
		-DCMAKE_C_COMPILER=clang \
		-DDEMO=ON

demo: configure-demo
	cmake --build build-demo

demo-run: demo
	open $(SIMULATOR) --args $(CURDIR)/$(PDX)

# ─── Device (demo) ──────────────────────────────────────────────────

.PHONY: configure-demo-device demo-device demo-deploy

configure-demo-device:
	cmake -B build-demo-device \
		-DCMAKE_BUILD_TYPE=Release \
		-DTOOLCHAIN=armgcc \
		-DDEMO=ON \
		--toolchain=$(SDK_PATH)/C_API/buildsupport/arm.cmake

demo-device: configure-demo-device
	cmake --build build-demo-device

demo-deploy: demo-device
	@DEVICE=$$(ls /dev/cu.usbmodem* 2>/dev/null | head -1); \
	if [ -z "$$DEVICE" ]; then \
		echo "Error: No Playdate device found. Connect via USB and unlock the device."; \
		exit 1; \
	fi; \
	echo "Found Playdate at $$DEVICE"; \
	echo "Mounting data disk..."; \
	$(PDUTIL) "$$DEVICE" datadisk; \
	echo "Waiting for device to reboot into data disk mode..."; \
	while [ -e "$$DEVICE" ]; do sleep 0.1; done; \
	echo "Waiting for volume to mount..."; \
	while [ ! -d "$(PLAYDATE_VOLUME)/Games" ]; do sleep 0.1; done; \
	echo "Syncing $(PDX) to device..."; \
	mkdir -p "$(GAMES_DIR)/$(PDX)"; \
	rsync -urtv --delete --exclude '.*' $(CURDIR)/$(PDX)/ "$(GAMES_DIR)/$(PDX)/"; \
	echo "Ejecting..."; \
	diskutil eject "$(PLAYDATE_VOLUME)"; \
	echo "Waiting for device to reconnect..."; \
	while [ -z "$$(ls /dev/cu.usbmodem* 2>/dev/null)" ]; do sleep 0.1; done; \
	sleep 1; \
	DEVICE=$$(ls /dev/cu.usbmodem* 2>/dev/null | head -1); \
	echo "Running $(PDX) on device..."; \
	$(PDUTIL) "$$DEVICE" run /Games/$(PDX)

# ─── Release packaging ──────────────────────────────────────────────

.PHONY: release release-demo

release: device
	cmake --build build-device --target package_device
	@echo "Release zip created in releases/"

release-demo: demo-device
	cmake --build build-demo-device --target package_device
	@echo "Demo release zip created in releases/"

# ─── Audio ───────────────────────────────────────────────────────────

.PHONY: audio-convert audio-normalize

# Convert all sounds to Playdate-compatible format (mono 16-bit PCM at 11025Hz)
audio-convert:
	bash scripts/convert_audio.sh

# Analyze loudness of all sounds, or normalize to TARGET_DB LUFS.
# Examples:
#   make audio-normalize              (analyze only)
#   make audio-normalize TARGET_DB=-16
#   make audio-normalize TARGET_DB=-16 DRY=1
audio-normalize:
	$(eval ARGS := $(if $(TARGET_DB),--target $(TARGET_DB),))
	$(eval ARGS := $(ARGS) $(if $(DRY),--dry,))
	bash scripts/normalize_audio.sh $(ARGS)

# ─── Utilities ───────────────────────────────────────────────────────

.PHONY: clean mount

mount:
	@DEVICE=$$(ls /dev/cu.usbmodem* 2>/dev/null | head -1); \
	if [ -z "$$DEVICE" ]; then \
		echo "Error: No Playdate device found. Connect via USB and unlock the device."; \
		exit 1; \
	fi; \
	echo "Found Playdate at $$DEVICE"; \
	echo "Mounting data disk..."; \
	$(PDUTIL) "$$DEVICE" datadisk; \
	echo "Waiting for volume to mount..."; \
	while [ ! -d "$(PLAYDATE_VOLUME)" ]; do sleep 0.1; done; \
	echo "Playdate mounted at $(PLAYDATE_VOLUME)"; \
	open "$(PLAYDATE_VOLUME)"

clean:
	rm -rf build build-device build-demo build-demo-device

# Default target
.DEFAULT_GOAL := build
