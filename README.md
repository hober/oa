# oa

This began life as a shell alias for `open -a`. Eventually I wrote a replacement in Python, because I wanted it to be able to also do the equivalent of `which` but for Mac apps.

At some point I translated it to Swift to speed it up.

Over time it grew the ability to reveal apps in the Finder and got ported to Linux.

## Building `oa`

You’ll need a Swift compiler and GNU Make installed. With those prerequisites in place, simply invoking `make` will build `oa`.

## Installing `oa`

Invoking `make install` will install `oa` in `/usr/local/bin`.

If you’d rather it go in `$foo/bin`, you can pass an appropriate value for `prefix` like so:

```
make install prefix=$foo
```
