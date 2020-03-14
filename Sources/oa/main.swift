import Foundation
import CoreServices

import ArgumentParser

struct OA: ParsableCommand {
  @Flag(name: .shortAndLong, help: "suppress all output")
  var quiet: Bool
  @Flag(name: [.customShort("d"), .long],
    help: "just locate the app (don't launch it)")
  var which: Bool
  @Argument(help: "the applications to run")
  var apps: [String]

  func log(_ result: OSStatus) {
    switch result {
    case kLSAppInTrashErr:
      CFShow("The application cannot be run because it is inside a Trash folder." as CFString)
    case kLSUnknownErr:
      CFShow("An unknown error has occurred." as CFString)
    case kLSNotAnApplicationErr:
      CFShow("The item to be registered is not an application." as CFString)
    case kLSNotInitializedErr:
      CFShow("Formerly returned by LSInit on initialization failure; no longer used." as CFString)
    case kLSDataUnavailableErr:
      CFShow("Data of the desired type is not available (for example, there is no kind string as CFString)." as CFString)
    case kLSApplicationNotFoundErr:
      CFShow("No application in the Launch Services database matches the input criteria." as CFString)
    case kLSUnknownTypeErr:
      CFShow("Not currently used." as CFString)
    case kLSDataTooOldErr:
      CFShow("Not currently used." as CFString)
    case kLSDataErr:
      CFShow("Data is structured improperly (for example, an item’s information property list is malformed as CFString). Not used in macOS 10.4." as CFString)
    case kLSLaunchInProgressErr:
      CFShow("A launch of the application is already in progress." as CFString)
    case kLSNotRegisteredErr:
      CFShow("Not currently used." as CFString)
    case kLSAppDoesNotClaimTypeErr:
      CFShow("Not currently used." as CFString)
    case kLSAppDoesNotSupportSchemeWarning:
      CFShow("Not currently used." as CFString)
    case kLSServerCommunicationErr:
      CFShow("There is a problem communicating with the server process that maintains the Launch Services database." as CFString)
    case kLSCannotSetInfoErr:
      CFShow("The filename extension to be hidden cannot be hidden." as CFString)
    case kLSNoRegistrationInfoErr:
      CFShow("Not currently used." as CFString)
    case kLSIncompatibleSystemVersionErr:
      CFShow("The application to be launched cannot run on the current Mac OS version." as CFString)
    case kLSNoLaunchPermissionErr:
      CFShow("The user does not have permission to launch the application (on a managed network as CFString)." as CFString)
    case kLSNoExecutableErr:
      CFShow("The executable file is missing or has an unusable format." as CFString)
    case kLSNoClassicEnvironmentErr:
      CFShow("The Classic emulation environment was required but is not available." as CFString)
    case kLSMultipleSessionsNotSupportedErr:
      CFShow("The application to be launched cannot run simultaneously in two different user sessions." as CFString)
    default:
      CFShow("Who the fuck knows" as CFString)
    }
  }

  func locate(_ app: CFString) -> CFURL? {
    var url: Unmanaged<CFURL>?
    let status = LSFindApplicationForInfo(kLSUnknownCreator, nil, app, nil, &url)
    if status != 0 {
      log(status)
    }
    return url?.takeRetainedValue()
  }

  func locate(app: CFString) -> Int {
    if let located = locate(app) {
      if !quiet {
        if let path = CFURLCopyFileSystemPath(located,
          CFURLPathStyle.cfurlposixPathStyle) {
          print("\(path)")
        } else {
          print("\(located)")
        }
      }
      return 0
    } else {
      return 1
    }
  }

  func launch(app: CFString) -> Int32 {
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
        log(status)
      }
      return status as Int32
    } else {
      return 1
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
        guard locate(app: "\(app).app" as CFString) == 0 else {
          throw OAError.couldNotLocate
        }
      } else {
        guard launch(app: "\(app).app" as CFString) == 0 else {
          throw OAError.couldNotLaunch
        }
      }
    }
  }
}

OA.main()
