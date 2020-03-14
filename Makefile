.PHONY: build install clean pristine

.build/debug/oa build:
	xcrun swift build

# $sysname is set in my shell config; it's where I put binaries I've
# built myself
install: .build/debug/oa
	cp .build/debug/oa ~/${sysname}/bin

clean:
	rm -f *~ .build/debug/oa

pristine: clean
	rm -rf .build Package.resolved
