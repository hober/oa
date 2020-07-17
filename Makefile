.PHONY: build docs install clean pristine

BINARY=.build/release/oa

ifeq ($(shell uname -s),Linux)
  SWIFT=swift
else
  SWIFT=xcrun swift
endif

$(BINARY) build: Sources/oa/main.swift
	$(SWIFT) build -c release

docs:
	jazzy --output Documentation --min-acl internal

MACHTYPE = $(shell uname -m | tr '[:upper:]' '[:lower:]')
OSTYPE = $(shell uname -s | tr '[:upper:]' '[:lower:]')
PREFIX ?= ~/$(MACHTYPE)-$(OSTYPE)
EXEC_PREFIX ?= $(PREFIX)
BINDIR ?= $(EXEC_PREFIX)/bin

install: $(BINARY)
	@mkdir -p $(BINDIR)
	cp $(BINARY) $(BINDIR)

clean:
	rm -rf $(BINARY)*

pristine:
	rm -rf .build Documentation Package.resolved
