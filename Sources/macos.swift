#if os(macOS)

import Foundation

/* fileprivate */ import class Cocoa.NSWorkspace

/// Describes an error encountered while calling into Launch Services.
internal struct LaunchServicesError: Error, CustomStringConvertible {
    /// The status code returned by a Launch Services method.
    let status: OSStatus

    /// The name of the app being operated on.
    let app: String

    var description: String {
        return switch status {
        case kLSAppInTrashErr:
            "'\(app)' is in the Trash."
        case kLSNotAnApplicationErr:
            "'\(app)' is not an app."
        case kLSDataUnavailableErr:
            "Data of the desired type is not available."
        case kLSApplicationNotFoundErr:
            "Unknown app '\(app)'."
        case kLSDataErr:
            "Improper data structure."
        case kLSLaunchInProgressErr:
            "'\(app)' is already being launched."
        case kLSServerCommunicationErr:
            "Can't talk to the Launch Services database."
        case kLSCannotSetInfoErr:
            "The system can’t hide the filename extension."
        case kLSIncompatibleSystemVersionErr:
            "'\(app)' can't run on this version of macOS."
        case kLSNoLaunchPermissionErr:
            "You don't have permission to launch '\(app)'."
        case kLSNoExecutableErr:
            "'\(app)' is corrupted and can't be run."
        case kLSMultipleSessionsNotSupportedErr:
            "Another user is already running '\(app)'."
        default:
            "An unknown error with '\(app)' has occurred."
        }
    }
}

/**
 Reveal files in the Finder.

 A simple wrapper around [`activateFileViewerSelecting(_:)`](https://developer.apple.com/documentation/appkit/nsworkspace/1524549-activatefileviewerselecting/).

 - Parameter urls: file:/// URLs to each file to reveal.
 */
internal func reveal(urls: [URL], withConfig _: Config) throws {
    NSWorkspace.shared.activateFileViewerSelecting(urls)
}

/**
 Return a file URL to the given app.

 A simple wrapper around deprecated
 [`LSFindApplicationForInfo(_:_:_:_:_:)`](https://developer.apple.com/documentation/coreservices/1449588-lsfindapplicationforinfo).
 I don't know of a non-deprecated way to find an app by name.

 - Parameter appName: The name of the app to locate.
 - Returns: a URL to the app.
 - Throws: Throws a ``LaunchServicesError`` if Launch Services returned an error code.
 */
internal func locateApp(byName appName: String) throws -> URL {
    var possibleURL: Unmanaged<CFURL>?

    let located = LSFindApplicationForInfo(
        kLSUnknownCreator, nil, "\(appName).app" as CFString, nil,
        &possibleURL)

    guard let url = possibleURL else {
        throw LaunchServicesError(status: located, app: appName)
    }

    return url.takeRetainedValue() as URL
}

/**
 Launch an app.

 A simple wrapper around [`LSOpenCFURLRef(_:_:)`](https://developer.apple.com/documentation/coreservices/1442850-lsopencfurlref).

 - Parameter url: the URL to the app.
 - Parameter appName: A human-readable name of the app.
 - Throws: Throws a ``LaunchServicesError`` if Launch Services returned an error code.
 */
internal func launchApp(byURL url: URL, withName appName: String) throws {
    var launchedURL: Unmanaged<CFURL>?

    let launched = LSOpenCFURLRef(url as CFURL, &launchedURL)

    if launched != noErr {
        throw LaunchServicesError(status: launched, app: appName)
    }
}

#endif
