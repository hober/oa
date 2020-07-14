import CoreFoundation
import CoreServices
import Darwin

import ArgumentParser

/// A TextOutputStream that writes to stderr.
struct StandardError: TextOutputStream {
  // Write to stderr.
  mutating func write(_ string: String) {
    fputs(string, Darwin.stderr)
  }
}

/// An instance of `StandardError`.
var stderr = StandardError()

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

  /// Log a LocationServices error.
  func log(_ result: OSStatus, _ app: Any) {
    if quiet {
      return
    }
    switch result {
    case kLSAppInTrashErr:
      print("Error: The application '\(app)' cannot be run because it is inside a Trash folder.", to: &stderr)
    case kLSApplicationNotFoundErr:
      print("Error: No application in the Launch Services database matches the input criteria  '\(app)'.", to: &stderr)
    case kLSLaunchInProgressErr:
      print("Error: A launch of the application '\(app)' is already in progress.", to: &stderr)
    case kLSServerCommunicationErr:
      print("Error: There is a problem communicating with the server process that maintains the Launch Services database.", to: &stderr)
    case kLSIncompatibleSystemVersionErr:
      print("Error: The application '\(app)' cannot run on the current macOS version.", to: &stderr)
    case kLSNoLaunchPermissionErr:
      print("Error: The user does not have permission to launch the application '\(app)' (on a managed network).", to: &stderr)
    case kLSNoExecutableErr:
      print("Error: The executable file in '\(app)' is missing or has an unusable format.", to: &stderr)
    case kLSNoClassicEnvironmentErr:
      print("Error: The Classic emulation environment was required for '\(app)' but is not available.", to: &stderr)
    case kLSMultipleSessionsNotSupportedErr:
      print("Error: The application to be launched '\(app)' cannot run simultaneously in two different user sessions.", to: &stderr)
    default:
      print("Error: An unknown error with '\(app)' has occurred.", to: &stderr)
    }
  }

  /// Given an app name, returns a CFURL to its location.
  func urlForApp(_ app: String) -> CFURL? {
    let filename = "\(app).app" as! CFString
    var url: Unmanaged<CFURL>?
    let status = LSFindApplicationForInfo(kLSUnknownCreator, nil,
      filename, nil, &url)
    if status != 0 {
      log(status, app)
    }
    return url?.takeRetainedValue()
  }

  /// Locate the given app.
  func locate(_ app: String) -> Int32 {
    if let located = urlForApp(app) {
      if !quiet {
        if let path = CFURLCopyFileSystemPath(located,
          CFURLPathStyle.cfurlposixPathStyle) {
          print("\(path)")
        } else {
          print("\(located)")
        }
      }
      return EXIT_SUCCESS
    } else {
      return EXIT_FAILURE
    }
  }

  /// Launch the given app.
  func launch(_ app: String) -> Int32 {
    var launched: Unmanaged<CFURL>?
    if let located = urlForApp(app) {
      if !quiet {
        if let path = CFURLCopyFileSystemPath(located,
          CFURLPathStyle.cfurlposixPathStyle) {
          print("Launching \(path)")
        } else {
          print("Launching \(located)")
        }
      }
      let status = LSOpenCFURLRef(located, &launched)
      if status != 0 {
        log(status, located)
      }
      return status as Int32
    } else {
      return EXIT_FAILURE
    }
  }

  /// Validate command line arguments.
  func validate() {
    guard !apps.isEmpty else {
      let error = ValidationError("You must specify at least one app to run.")
      OA.exit(withError: error)
    }
  }

  /// Run the command.
  func run() {
    let operation: (String) -> Int32 = which ? locate : launch;

    for app in apps {
      guard operation(app) == 0 else {
        Darwin.exit(EXIT_FAILURE)
      }
    }

    Darwin.exit(EXIT_SUCCESS)
  }
}

OA.main()
