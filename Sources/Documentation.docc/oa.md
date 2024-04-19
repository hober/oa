# ``oa``

Quickly launch apps from the command line.

## Overview

If you’ve used `open -a` to launch a macOS application, `oa` will feel very familar. In fact, it started life as a simple shell alias for `open -a`:

```zsh
alias oa='open -a'
```

It grew beyond this humble beginning because I wanted to add two features:

1. I wanted to be able to launch more than one app at a time,
2. and I wanted to be able to find out *where* an app is, with or without launching it.

`oa` can do both of these things, and it can also reveal apps in your file manager. (On macOS, this is the Finder.)

### Launching apps

The most typical use of `oa` is to launch an application, like so:

```shell
$ oa textedit
Launching /System/Applications/TextEdit.app
```

You can launch as many apps as you’d like:

```shell
$ oa music mail calendar
Launching /System/Applications/Music.app
Launching /System/Applications/Mail.app
Launching /System/Applications/Calendar.app
```

If there’s no such app, or some other error occurs, `oa` will let you know:

```shell
$ oa flarg
oa: Unknown app 'flarg'.
```

**Supressing output**: If you don’t want `oa` to tell you where the apps it’s launching are, you can pass in the `-q` (quiet) option.

### Locating apps

You can give `oa` the `-d` (for "directory") option if you want to know where an app is but you don’t want to launch it.

```shell
$ oa -d safari
/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app
```

This can be useful in shell scripts. For example:

```zsh
emacs_app=`oa -d Emacs 2> /dev/null`
if (( $? == 0 )); then
    alias emacs="$emacs_app/Contents/MacOS/Emacs -nw"
    path=($emacs_app/Contents/MacOS/bin $path)
fi
```

Speaking of shell scripts, combining the `-d` and `-q` options can be useful when you just want to know if an app is present on the system—simply check the return code:

```zsh
if oa -dq Firefox; then
    alias ff="oa Firefox"
fi
```

### Revealing apps

The `-r` option causes the app(s) to be revealed in your file manager instead of launched. For instance, this is how you get a file manager window with `Maps.app` selected:

```shell
$ oa -r maps
```

## Topics

### The `oa` command-line utility

- ``OpenApp``
- ``OpenApp/run()``

### Command-line arguments

- ``OpenApp/apps``
- ``OpenApp/operation``
- ``OpenApp/quiet``

- ``OpenApp/validate()``

### Launching, locating, and revealing apps

- ``Operation``
- ``Operation/launch``
- ``launchApp(byURL:withName:)``
- ``Operation/locate``
- ``locateApp(byName:)``
- ``Operation/reveal``
- ``reveal(urls:withConfig:)``
- ``LaunchServicesError``

### Configuration file

- ``OpenApp/loadUserConfig(from:)``
- ``Aliases``
- ``Config``
- ``ConfigFileError``
- ``defaultLinuxFileManager``

### Diagnostic output

- ``log(error:)``
