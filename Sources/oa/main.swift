import CoreFoundation
import CoreServices
import Darwin

import ArgumentParser

/// A TextOutputStream that writes to stderr.
struct StandardError: TextOutputStream {
  /// Write to stderr.
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

  /**
    Log a LocationServices error.

    - Parameter result: The status code to log.
    - Parameter app: The app in question.
  */
  func logError(_ result: OSStatus, _ app: Any) {
    if quiet {
      return
    }
    switch result {
    case kLSAppInTrashErr:
      print("oa: '\(app)' cannot be run because it is in the Trash.", to: &stderr)
    case kLSApplicationNotFoundErr:
      print("oa: Launch Services doesn't know of an app named '\(app)'.", to: &stderr)
    case kLSLaunchInProgressErr:
      print("oa: '\(app)' is already being launched.", to: &stderr)
    case kLSServerCommunicationErr:
      print("oa: Failed to communicate with the Launch Services database.", to: &stderr)
    case kLSIncompatibleSystemVersionErr:
      print("oa: '\(app)' can't run on this version of macOS.", to: &stderr)
    case kLSNoLaunchPermissionErr:
      print("oa: You don't have permission to launch '\(app)' (on a managed network).", to: &stderr)
    case kLSNoExecutableErr:
      print("oa: '\(app)' is corrupted and can't be run.", to: &stderr)
    case kLSNoClassicEnvironmentErr:
      print("oa: Classic apps like '\(app)' can no longer be run.", to: &stderr)
    case kLSMultipleSessionsNotSupportedErr:
      print("oa: '\(app)' can't be run because another user is already running it.", to: &stderr)
    default:
      print("oa: An unknown error with '\(app)' has occurred.", to: &stderr)
    }
  }

  /**
    Return a URL for the given app.

    - Parameter app: The app to locate.
    - Returns: a `CFURL` to the app, or `nil` if it was not found.
  */
  func urlForApp(_ app: String) -> (OSStatus, CFURL?) {
    let filename = "\(app).app" as! CFString
    var url: Unmanaged<CFURL>?
    let status = LSFindApplicationForInfo(kLSUnknownCreator, nil,
      filename, nil, &url)
    return (status, url?.takeRetainedValue())
  }

  /**
    Locate the given app.

    - Parameter app: The app to locate.
    - Returns: A status code.
  */
  func locate(_ app: String) -> OSStatus {
    let (status, located) = urlForApp(app)
    if located != nil {
      if !quiet {
        if let path = CFURLCopyFileSystemPath(located,
          CFURLPathStyle.cfurlposixPathStyle) {
          print("\(String(describing:path))")
        } else {
          print("\(String(describing:located))")
        }
      }
    }
    if status != 0 {
      logError(status, app)
    }
    return status
  }

  /**
    Launch the given app.

    - Parameter app: The app to launch.
    - Returns: `EXIT_SUCCESS` or `EXIT_FAILURE`.
  */
  func launch(_ app: String) -> OSStatus {
    var launched: Unmanaged<CFURL>?
    let (locateStatus, located) = urlForApp(app)
    if located != nil {
      if !quiet {
        if let path = CFURLCopyFileSystemPath(located,
          CFURLPathStyle.cfurlposixPathStyle) {
          print("Launching \(String(describing:path))")
        } else {
          print("Launching \(String(describing:located))")
        }
      }
      let launchStatus = LSOpenCFURLRef(located!, &launched)
      if launchStatus != 0 {
        logError(launchStatus, app)
      }
      return launchStatus
    }
    if locateStatus != 0 {
      logError(locateStatus, app)
    }
    return locateStatus
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
    let operation: (String) -> OSStatus = which ? locate : launch;

    for app in apps {
      let status = operation(app)
      guard status == 0 else {
        Darwin.exit(status as Int32)
      }
    }

    Darwin.exit(EXIT_SUCCESS)
  }
}

OA.main()
