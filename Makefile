.PHONY: build install clean pristine

.build/debug/oa build:
	xcrun swift build

install: .build/debug/oa
	cp .build/debug/oa ~/${sysname}/bin

clean:
	rm -f *~ .build/debug/oa

pristine: clean
	rm -rf .build Package.resolved
