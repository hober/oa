# -*- makefile-gmake -*-

.PHONY: all clean distclean docs install installdirs oa view-docs uninstall

SHELL = /bin/sh

DOCCARCHIVE=.build/plugins/Swift-DocC/outputs/oa.doccarchive
SRCS = Sources/oa.swift

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

BUILD_DIR = .build/release
BINARY=oa

XCRUN = $(shell command -v xcrun 2>/dev/null)
CODESIGN = $(shell command -v codesign 2>/dev/null)
ETAGS = $(shell command -v etags 2>/dev/null)
ifdef XCRUN
SWIFT = $(XCRUN) swift
else
SWIFT = $(shell command -v swift 2>/dev/null)
endif

oa: $(BUILD_DIR)/$(BINARY)

all: $(BUILD_DIR)/$(BINARY) $(DOCCARCHIVE)

clean:
	$(SWIFT) package clean

distclean: clean
	rm -rf .build Package.resolved .swiftpm TAGS

docs: $(DOCCARCHIVE)

install: $(BUILD_DIR)/$(BINARY) installdirs
	$(INSTALL_PROGRAM) $(BUILD_DIR)/$(BINARY) \
		$(DESTDIR)$(bindir)/$(BINARY)

installdirs:
	mkdir -p $(DESTDIR)$(bindir)

view-docs:
	open $(DOCCARCHIVE)

uninstall:
	rm $(DESTDIR)$(bindir)/$(BINARY)

$(BUILD_DIR)/$(BINARY): $(SRCS)
	$(SWIFT) build -c release
ifdef CODESIGN
	$(CODESIGN) -s hober $@
endif

$(DOCCARCHIVE): $(SRCS)
	$(SWIFT) package generate-documentation

TAGS: $(SRCS)
	$(ETAGS) $(SRCS)
