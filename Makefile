APP_NAME = Stash
BUNDLE_ID = com.stash.app
VERSION = 1.0.0
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
CONTENTS = $(APP_BUNDLE)/Contents
MACOS = $(CONTENTS)/MacOS
RESOURCES = $(CONTENTS)/Resources

.PHONY: all build bundle run clean

all: build bundle

build:
	swift build -c release

bundle: build
	mkdir -p $(MACOS)
	mkdir -p $(RESOURCES)
	cp $(BUILD_DIR)/$(APP_NAME) $(MACOS)/
	cp Info.plist $(CONTENTS)/

run: bundle
	open $(APP_BUNDLE)

clean:
	rm -rf .build
	rm -rf $(APP_BUNDLE)
