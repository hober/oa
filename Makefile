.PHONY: build docs install clean pristine

.build/release/oa build: Sources/oa/main.swift
	xcrun swift build -c release

docs:
	jazzy --output Documentation --min-acl internal

# $SYSNAME is set in my shell config; it's where I put binaries I've
# built myself.
install: .build/release/oa
	mkdir -p ~/${SYSNAME}/bin
	cp .build/release/oa ~/${SYSNAME}/bin

clean:
	rm -f *~ .build/release/oa

pristine: clean
	rm -rf .build Documentation Package.resolved
