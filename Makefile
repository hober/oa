# -*- makefile-gmake -*-

.PHONY: all clean distclean docs install installdirs view-docs uninstall

SHELL = /bin/sh

SRCS = Sources/*.swift
DOCS = Sources/Documentation.docc/*.md

prefix = /usr/local

exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
srcdir = .

INSTALL = install -c
INSTALL_PROGRAM = $(INSTALL)
INSTALL_DATA = $(INSTALL) -m 644

BUILD_DIR = .build/release
BINARY=oa
DOCCARCHIVE=.build/plugins/Swift-DocC/outputs/${BINARY}.doccarchive

XCRUN = $(shell command -v xcrun 2>/dev/null)
ETAGS = $(shell command -v etags 2>/dev/null)

CERT = hober
SECURITY = $(shell command -v security 2>/dev/null)
ifneq ($(strip $(SECURITY)),)
IDENTITY = $(shell security find-identity -p codesigning | grep -c $(CERT))
ifeq ($(IDENTITY),1)
CODESIGN = $(shell command -v codesign 2>/dev/null)
endif
endif

ifdef XCRUN
SWIFT = $(XCRUN) swift
else
SWIFT = $(shell command -v swift 2>/dev/null)
endif

# SWIFTCARGS=-Xswiftc -enable-experimental-feature -Xswiftc AccessLevelOnImport
SWIFTCARGS=

$(BUILD_DIR)/$(BINARY): $(SRCS)
	$(SWIFT) build -c release $(SWIFTCARGS)
ifdef CODESIGN
	$(CODESIGN) -s $(CERT) $@
endif

all: $(BUILD_DIR)/$(BINARY) $(DOCCARCHIVE)

clean:
	rm -f Sources/*~ $(BUILD_DIR)/$(BINARY)

distclean: clean
	$(SWIFT) package clean
	rm -rf .build Package.resolved .swiftpm TAGS

docs: $(DOCCARCHIVE)

install: $(DESTDIR)$(bindir)/$(BINARY)

installdirs: $(DESTDIR)$(bindir)

view-docs:
	open $(DOCCARCHIVE)

uninstall:
	rm $(DESTDIR)$(bindir)/$(BINARY)

$(DESTDIR)$(bindir)/$(BINARY): $(DESTDIR)$(bindir) $(BUILD_DIR)/$(BINARY)
	$(INSTALL_PROGRAM) $(BUILD_DIR)/$(BINARY) $(DESTDIR)$(bindir)/$(BINARY)

$(DESTDIR)$(bindir):
	mkdir -p $@

$(DOCCARCHIVE): $(SRCS) $(DOCS)
	$(SWIFT) package generate-documentation

TAGS: $(SRCS)
	$(ETAGS) $(SRCS)
