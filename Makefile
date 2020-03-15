.PHONY: build install clean pristine

.build/release/oa build: Sources/oa/main.swift
	xcrun swift build -c release

# $sysname is set in my shell config; it's where I put binaries I've
# built myself
install: .build/release/oa
	cp .build/release/oa ~/${sysname}/bin

clean:
	rm -f *~ .build/release/oa

pristine: clean
	rm -rf .build Package.resolved
