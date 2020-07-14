.PHONY: build docs install clean pristine

.build/release/oa build: Sources/oa/main.swift
	xcrun swift build -c release

docs:
	jazzy --output Documentation --min-acl internal

MACHTYPE = $(shell uname -m | tr '[:upper:]' '[:lower:]')
OSTYPE = $(shell uname -s | tr '[:upper:]' '[:lower:]')
PREFIX ?= ~/$(MACHTYPE)-$(OSTYPE)
EXEC_PREFIX ?= $(PREFIX)
BINDIR ?= $(EXEC_PREFIX)/bin

install: .build/release/oa
	@mkdir -p $(BINDIR)
	cp .build/release/oa $(BINDIR)

clean:
	rm -rf .build/release/oa*

pristine:
	rm -rf .build Documentation Package.resolved
