import CoreFoundation
import Foundation

#if os(Linux)
import var Glibc.stderr
import func Glibc.exit
import func Glibc.fputs
import let Glibc.EXIT_SUCCESS
import let Glibc.EXIT_FAILURE
#else
import CoreServices
import var Darwin.stderr
import func Darwin.exit
import func Darwin.fputs
import let Darwin.EXIT_SUCCESS
import let Darwin.EXIT_FAILURE
#endif

import ArgumentParser

/// Exit the application.
let libcExit = exit

/// A TextOutputStream that writes to stderr.
struct StandardError: TextOutputStream {
  /// Write to stderr.
  mutating func write(_ string: String) {
    fputs(string, stderr)
  }
}

/// An instance of `StandardError`.
var standardError = StandardError()

/// The `oa` command itself.
struct OA: ParsableCommand {
  /// Additional help information.
  static let configuration = CommandConfiguration(
    abstract: "Launch apps by name.",
    discussion: """
Exits successfully if all the apps launch successfully.
Exits with an error code if an app could not be found or could not be run.
""")

  /// If non-`nil`, just locate the app, don't launch it.
  @Flag(name: [.customShort("d"), .long], help: ArgumentHelp(
      "Just locate the app; don't launch it.",
      discussion: """
For when you want to know where an app is on the filesystem.
Combine with -q to test for the existence of an app from a shell script.
"""
    ))
  var which: Bool = false

  /// If non-`nil`, suppress all printed output.
  @Flag(name: .shortAndLong, help: ArgumentHelp(
      "Suppress all output.",
      discussion: """
Check the exit code to know if the app was found and/or launched.
"""))
  var quiet: Bool = false

  /// The apps to run or locate.
  @Argument(help: ArgumentHelp(
      "The applications to run (or locate).",
      discussion: "You must specify at least one app."))
  var apps: [String] = []

  /**
    Log a LocationServices error.

    - Parameter result: The status code to log.
    - Parameter app: The app in question.
  */
  func logError(_ result: OSStatus, _ app: Any) {
    guard !quiet else {
      return
    }
    switch result {
#if !os(Linux)
    case kLSAppInTrashErr:
      print("oa: '\(app)' cannot be run because it is in the Trash.", to: &standardError)
    case kLSApplicationNotFoundErr:
      print("oa: Launch Services doesn't know of an app named '\(app)'.", to: &standardError)
    case kLSLaunchInProgressErr:
      print("oa: '\(app)' is already being launched.", to: &standardError)
    case kLSServerCommunicationErr:
      print("oa: Failed to communicate with the Launch Services database.", to: &standardError)
    case kLSIncompatibleSystemVersionErr:
      print("oa: '\(app)' can't run on this version of macOS.", to: &standardError)
    case kLSNoLaunchPermissionErr:
      print("oa: You don't have permission to launch '\(app)' (on a managed network).", to: &standardError)
    case kLSNoExecutableErr:
      print("oa: '\(app)' is corrupted and can't be run.", to: &standardError)
    case kLSNoClassicEnvironmentErr:
      print("oa: Classic apps like '\(app)' can no longer be run.", to: &standardError)
    case kLSMultipleSessionsNotSupportedErr:
      print("oa: '\(app)' can't be run because another user is already running it.", to: &standardError)
#endif
    default:
      print("oa: An unknown error with '\(app)' has occurred.", to: &standardError)
    }
  }

  /**
    Return a URL for the given app.

    - Parameter app: The app to locate.
    - Returns: a `CFURL` to the app, or `nil` if it was not found.
  */
#if os(Linux)
  func url(forApp app: String) -> (OSStatus, URL?) {
    let fm = FileManager.default

    guard let path = ProcessInfo.processInfo.environment["PATH"] else {
      libcExit(EXIT_FAILURE)
    }

    for dir in path.components(separatedBy: ":") {
      let dirURL = URL(fileURLWithPath: dir)
      do {
        let items = try fm.contentsOfDirectory(atPath: dir)
        for item in items {
          let itemURL = dirURL.appendingPathComponent(item, isDirectory:
            false)
          if item == app {
            return (EXIT_SUCCESS as OSStatus, itemURL)
          }
        }
      } catch {
        if !quiet {
          print("Unexpected error: \(error)", to:&standardError)
        }
        libcExit(EXIT_FAILURE)
      }
    }

    if !quiet {
      print("Command not found: \(app)", to:&standardError)
    }
    libcExit(EXIT_FAILURE)
  }
#else
  func url(forApp app: String) -> (OSStatus, CFURL?) {
    let filename = "\(app).app" as! CFString
    var url: Unmanaged<CFURL>?
    // This is deprecated, but I don't know of any other macOS API that,
    // given a string "foo.app", will tell you where the app is.
    let status = LSFindApplicationForInfo(kLSUnknownCreator, nil,
      filename, nil, &url)
    return (status, url?.takeRetainedValue())
  }
#endif

  /**
    Print the file system path corresponding to `url`.

    - Parameter url: The URL to convert to a path for printing.
    - Parameter prefix: A prefix to prepend to the printed output.
  */
  func printPath(fromURL url: CFURL, withPrefix prefix: String = "") {
    if let path = CFURLCopyFileSystemPath(url,
      CFURLPathStyle.cfurlposixPathStyle) {
      print("\(prefix)\(String(describing:path))")
    } else if !quiet { // I don't think this ever happens.
      print("""
        oa: don't know how to convert \(String(describing:url)) into \
        a file system path.
        """, to: &standardError)
    }
  }

  /**
    Print the file system path corresponding to `url`.

    - Parameter url: The URL to convert to a path for printing.
    - Parameter prefix: A prefix to prepend to the printed output.
  */
  func printPath(fromURL url: URL, withPrefix prefix: String = "") {
    print("\(prefix)\(url.path)")
  }

  /**
    Locate the given app.

    - Parameter app: The app to locate.
    - Returns: A status code.
  */
  func locate(_ app: String) -> OSStatus {
    let (status, appLocated) = url(forApp: app)

    if appLocated != nil && !quiet {
      printPath(fromURL: appLocated!)
    }

    return status
  }

  /**
    Launch the given app.

    - Parameter app: The app to launch.
    - Returns: `EXIT_SUCCESS` or `EXIT_FAILURE`.
  */
  func launch(_ app: String) -> OSStatus {
    let (status, appToLaunch) = url(forApp: app)

    guard appToLaunch != nil else {
      return status
    }

    if !quiet {
      printPath(fromURL: appToLaunch!, withPrefix: "Launching ")
    }

#if os(Linux)
    do {
      let task = Process()
      task.executableURL = appToLaunch
      task.arguments = []
      try task.run()

      let graphical = ProcessInfo.processInfo.environment["XDG_CURRENT_DESKTOP"] != nil
      // We should wait for command-line tasks to complete, but if we've
      // launched graphical programs, we don't need to wait.
      if !graphical {
        task.waitUntilExit()
      }
    } catch {
      OA.exit(withError:
        ValidationError("Invalid command: \(app)"))
    }
    return EXIT_SUCCESS as OSStatus
#else
    var launched: Unmanaged<CFURL>?
    return LSOpenCFURLRef(appToLaunch!, &launched)
#endif
  }

  /// Validate command line arguments.
  func validate() {
    guard !apps.isEmpty else {
      OA.exit(withError:
        ValidationError("You must specify at least one app to run."))
    }
  }

  /// Run the command.
  func run() {
    let operation: (String) -> OSStatus = which ? locate : launch;

    for app in apps {
      let status = operation(app)
      guard status == EXIT_SUCCESS else {
        libcExit(status as Int32)
      }
    }

    libcExit(EXIT_SUCCESS)
  }
}

OA.main()
