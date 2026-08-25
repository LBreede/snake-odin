ODIN ?= odin
SOURCE := game.odin
BUILD_DIR := build
TARGET := $(BUILD_DIR)/snake

.PHONY: all build release run check clean

all: build

build:
	mkdir -p $(BUILD_DIR)
	$(ODIN) build $(SOURCE) -file -debug -out:$(TARGET)

release:
	mkdir -p $(BUILD_DIR)
	$(ODIN) build $(SOURCE) -file -o:speed -out:$(TARGET)

run:
	$(ODIN) run $(SOURCE) -file

check:
	$(ODIN) check $(SOURCE) -file

clean:
	rm -rf $(BUILD_DIR)
