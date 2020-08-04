.PHONY: build docs install clean pristine

BINARY=.build/release/oa

$(BINARY) build: Sources/oa/main.swift
	swift build -c release

docs:
	jazzy --output Documentation --min-acl internal

MACHTYPE = $(shell uname -m | tr '[:upper:]' '[:lower:]')
OSTYPE = $(shell uname -s | tr '[:upper:]' '[:lower:]')
PREFIX ?= ~/$(MACHTYPE)-$(OSTYPE)
EXEC_PREFIX ?= $(PREFIX)
BINDIR ?= $(EXEC_PREFIX)/bin

sign: $(BINARY)
	codesign -s hober $(BINARY)

install: $(BINARY) sign
	cp $(BINARY) $(BINDIR)

clean:
	rm -rf $(BINARY)*

pristine:
	rm -rf .build Documentation Package.resolved
