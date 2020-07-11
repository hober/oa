import Foundation
import CoreServices

import ArgumentParser

struct OA: ParsableCommand {
  static let configuration = CommandConfiguration(
    abstract: "Launch apps by name.",
    discussion: """
Exits successfully if all the apps launch successfully.
Exits with an error code if an app could not be found or could not be run.
""")

  @Flag(name: [.customShort("d"), .long], help: ArgumentHelp(
      "Just locate the app; don't launch it.",
      discussion: """
For when you want to know where an app is on the filesystem.
Combine with -q to test for the existence of an app from a shell script.
"""
    ))
  var which: Bool = false

  @Flag(name: .shortAndLong, help: ArgumentHelp(
      "Suppress all output.",
      discussion: """
Check the exit code to know if the app was found and/or launched.
"""))
  var quiet: Bool = false

  @Argument(help: ArgumentHelp(
      "The applications to run.",
      discussion: "You must specify at least one app to run."))
  var apps: [String] = []

  func log(_ result: OSStatus, _ app: Any) {
    if quiet {
      return
    }
    switch result {
    case kLSAppInTrashErr:
      CFShow("Error: The application '\(app)' cannot be run because it is inside a Trash folder." as CFString)
    case kLSApplicationNotFoundErr:
      CFShow("Error: No application in the Launch Services database matches the input criteria  '\(app)'." as CFString)
    case kLSLaunchInProgressErr:
      CFShow("Error: A launch of the application '\(app)' is already in progress." as CFString)
    case kLSServerCommunicationErr:
      CFShow("Error: There is a problem communicating with the server process that maintains the Launch Services database." as CFString)
    case kLSIncompatibleSystemVersionErr:
      CFShow("Error: The application '\(app)' cannot run on the current macOS version." as CFString)
    case kLSNoLaunchPermissionErr:
      CFShow("Error: The user does not have permission to launch the application '\(app)' (on a managed network)." as CFString)
    case kLSNoExecutableErr:
      CFShow("Error: The executable file in '\(app)' is missing or has an unusable format." as CFString)
    case kLSNoClassicEnvironmentErr:
      CFShow("Error: The Classic emulation environment was required for '\(app)' but is not available." as CFString)
    case kLSMultipleSessionsNotSupportedErr:
      CFShow("Error: The application to be launched '\(app)' cannot run simultaneously in two different user sessions." as CFString)
    default:
      CFShow("Error: An unknown error with '\(app)' has occurred." as CFString)
    }
  }

  func locate(_ app: String) -> CFURL? {
    var url: Unmanaged<CFURL>?
    let status = LSFindApplicationForInfo(kLSUnknownCreator, nil,
      "\(app).app" as CFString, nil, &url)
    if status != 0 {
      log(status, app)
    }
    return url?.takeRetainedValue()
  }

  func locate(app: String) -> Int32 {
    if let located = locate(app) {
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

  func launch(app: String) -> Int32 {
    var launched: Unmanaged<CFURL>?
    if let located = locate(app) {
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

  enum OAError: Error {
    case couldNotLocate
    case couldNotLaunch
  }

  func run() throws {
    guard apps.count > 0 else {
      throw ValidationError("You must specify at least one app to run.")
    }

    for app in apps {
      if which {
        guard locate(app: app) == 0 else {
          if !quiet {
            throw OAError.couldNotLocate
          }
          Foundation.exit(EXIT_FAILURE)
        }
      } else {
        guard launch(app: app) == 0 else {
          if !quiet {
            throw OAError.couldNotLaunch
          }
          Foundation.exit(EXIT_FAILURE)
        }
      }
    }
  }
}

OA.main()
