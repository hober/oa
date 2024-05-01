#if os(macOS)

import Foundation

/* fileprivate */ import class Cocoa.NSWorkspace

struct MacAppLauncher: AppLauncher {
    let apps: [String]
    let quiet: Bool
    var urls: [URL] = []

    init(_ apps: [String], withConfig config: Config, quietly quiet: Bool) throws {
        self.apps = apps
        self.quiet = quiet

        let aliases = config.mergedAliases()

        self.urls = try apps.map {
            try locateMacApp(byName: aliases[$0] ?? $0)
        }
    }

    /**
     Launch the apps.

     A simple wrapper around [`LSOpenCFURLRef(_:_:)`](https://developer.apple.com/documentation/coreservices/1442850-lsopencfurlref).

     - Throws: Throws a ``LaunchServicesError`` if Launch Services returned an error code.
     */
    func launchApps() throws {
        for (i, url) in urls.enumerated() {
            var launchedURL: Unmanaged<CFURL>?

            let launched = LSOpenCFURLRef(url as CFURL, &launchedURL)

            if launched != noErr {
                throw LauncherError.platformError(
                    launched,
                    LaunchServicesError(status: launched, app: apps[i]))
            } else if !quiet {
                print("Launching \(url.path)")
            }
        }
    }

    func locateApps() throws {
        guard !quiet else {
            return
        }
        for url in urls {
            print(url.path)
        }
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
    internal func locateMacApp(byName appName: String) throws -> URL {
        var possibleURL: Unmanaged<CFURL>?

        let located = LSFindApplicationForInfo(
            kLSUnknownCreator, nil, "\(appName).app" as CFString, nil,
            &possibleURL)

        guard let url = possibleURL else {
            throw LauncherError.platformError(
                located,
                LaunchServicesError(status: located, app: appName))
        }

        return url.takeRetainedValue() as URL
    }

    /**
     Reveal files in the Finder.

     A simple wrapper around [`activateFileViewerSelecting(_:)`](https://developer.apple.com/documentation/appkit/nsworkspace/1524549-activatefileviewerselecting/).
     */
    func revealApps() throws {
        NSWorkspace.shared.activateFileViewerSelecting(urls)
        guard !quiet else {
            return
        }
        for url in urls {
            print("Revealing \(url.path)")
        }
    }
}

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

#endif
