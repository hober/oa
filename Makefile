# -*- makefile-gmake -*-

.PHONY: all clean distclean documentation install installdirs uninstall

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

XCRUN = $(shell command -v xcrun 2>/dev/null)
ETAGS = etags

CERT = hober
SECURITY = $(shell command -v security 2>/dev/null)
ifneq ($(strip $(SECURITY)),)
IDENTITY = $(shell security find-identity -p codesigning | grep -c $(CERT))
ifeq ($(IDENTITY),1)
CODESIGN = $(shell command -v codesign 2>/dev/null)
endif
endif

SWIFT = $(XCRUN) swift

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
	rm -rf .build .swiftpm Package.resolved TAGS docs

documentation: docs/documentation/$(BINARY)/index.html

install: $(DESTDIR)$(bindir)/$(BINARY)

installdirs: $(DESTDIR)$(bindir)

uninstall:
	rm $(DESTDIR)$(bindir)/$(BINARY)

$(DESTDIR)$(bindir)/$(BINARY): $(DESTDIR)$(bindir) $(BUILD_DIR)/$(BINARY)
	$(INSTALL_PROGRAM) $(BUILD_DIR)/$(BINARY) $(DESTDIR)$(bindir)/$(BINARY)

$(DESTDIR)$(bindir) docs:
	mkdir -p $@

docs/documentation/$(BINARY)/index.html: docs $(SRCS) $(DOCS)
	$(SWIFT) package --allow-writing-to-directory ./docs \
		generate-documentation --target $(BINARY) \
		--disable-indexing --transform-for-static-hosting \
		--hosting-base-path $(BINARY) --output-path ./docs

TAGS: $(SRCS)
	$(ETAGS) $(SRCS)
