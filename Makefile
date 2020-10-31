# -*- makefile-gmake -*-

.PHONY: all clean distclean html install installdirs uninstall

SHELL = /bin/sh

# $(prefix) should default to /usr/local, but as this is a personal
# project I default it to ~/$SYSNAME/bin, which is where I put personal
# binaries.
MACHTYPE = $(shell uname -m | tr '[:upper:]' '[:lower:]')
OSTYPE = $(shell uname -s | tr '[:upper:]' '[:lower:]')
prefix = ~/$(MACHTYPE)-$(OSTYPE)

exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
srcdir = .

INSTALL = install -c
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

CODESIGN = codesign
SWIFT = swift
JAZZY = jazzy

BUILD_DIR = .build/release
BINARY=oa

SRCS = Sources/oa/main.swift

all: $(BUILD_DIR)/$(BINARY)

clean:
	rm -rf $(BUILD_DIR)/$(BINARY)*

distclean: clean
	rm -rf .build Documentation Package.resolved TAGS

html: Documentation/index.html

install: all installdirs
	$(INSTALL_PROGRAM) $(BUILD_DIR)/$(BINARY) \
		$(DESTDIR)$(bindir)/$(BINARY)

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

uninstall:
	rm $(DESTDIR)$(bindir)/$(BINARY)

$(BUILD_DIR)/$(BINARY): $(SRCS)
	$(SWIFT) build -c release
ifeq ($(shell uname -s),Darwin)
	$(CODESIGN) -s hober $@
endif

Documentation/index.html: $(SRCS)
ifeq ($(shell uname -s),Darwin)
	$(JAZZY) --output Documentation --min-acl internal
else
	@echo "Can't build docs on Linux yet."
endif

TAGS: $(SRCS)
	etags $(SRCS)
