import Cocoa

import ArgumentParser
import TOMLDecoder

/// The per-user OA configuration file.
private let dotfile = "~/.oarc"

/// A struct representing the contents of the user's `oa` config file.
public struct Config: Codable {
    /// App aliases for things that are too long to type out by hand.
    let aliases: [String: String]
}

/// Operations the user may request to perform on apps.
public enum Operation: String, EnumerableFlag {
    /// Launch the apps.
    case launch
    /// Locate the apps on the filesystem.
    case locate
    /// Reveal the apps in Finder.
    case reveal
}

/// Implementation of the `oa` command.
struct OpenApp: ParsableCommand {
    /// Run the command.
    internal mutating func run() throws {
        try loadUserConfig(from: dotfile)

        let urls = try apps.map { try locateApp(named: $0) }

        if operation == .reveal {
            NSWorkspace.shared.activateFileViewerSelecting(urls)
            return
        }

        for (index, url) in urls.enumerated() {
            if !quiet {
                operation.announce(url)
            }

            guard operation == .launch else {
                continue
            }

            var launchedURL: Unmanaged<CFURL>?

            let launched = LSOpenCFURLRef(url as CFURL, &launchedURL)

            if launched != noErr {
                throw fail(withErrorCode: launched, forApp: apps[index])
            }
        }
    }

    /**
     Return a file URL to the given app.

     - Parameter appName: The name of the app to locate.
     - Returns: a URL to the app.
     */
    private func locateApp(named appName: String) throws -> URL {
        let filename = "\(aliases[appName] ?? appName).app"

        var possibleURL: Unmanaged<CFURL>?

        // LSFindApplicationForInfo is deprecated, but I don't know of
        // any other macOS API that, given a string "foo.app", will tell
        // you where it is.
        let located = LSFindApplicationForInfo(
            kLSUnknownCreator, nil, filename as CFString, nil, &possibleURL)

        guard let url = possibleURL else {
            throw fail(withErrorCode: located, forApp: appName)
        }

        return url.takeRetainedValue() as URL
    }

    /// App name aliases loaded from the user's OA config file.
    public var aliases: [String: String] = [:]

    /// Load the user's dotfile.
    private mutating func loadUserConfig(from filename: String) throws {
        do {
            let contents = try Data(
                contentsOf: URL(
                    fileURLWithPath:
                      NSString(string: filename).expandingTildeInPath))
            let conf = try TOMLDecoder().decode(Config.self, from: contents)
            aliases = conf.aliases
        } catch let error as NSError where error.code == 260 {
            // Missing config file is OK; you don't have to have one.
        } catch DecodingError.keyNotFound(let key, _) {
            print("""
oa: \(filename) is missing an [\(key.stringValue)] section.
""", to: &standardError)
            throw ExitCode(1)
        } catch DecodingError.dataCorrupted(let context) {
            describeDataCorruptionError(context, filename)
            throw ExitCode(1)
        } catch DecodingError.typeMismatch(let type, let context) {
            let path = (context.codingPath.map { $0.stringValue }).joined(
                separator: ".")
            print("oa: Type mismatch at\(path) in \(filename): \(type)",
                  to: &standardError)
            throw ExitCode(1)
        } catch DecodingError.valueNotFound(let type, let context) {
            let path = (context.codingPath.map { $0.stringValue }).joined(
                separator: ".")
            print("oa: \(path) is not a \(type) in \(filename)!",
                  to: &standardError)
            throw ExitCode(1)
        } catch {
            print("oa: \(error)", to: &standardError)
            throw ExitCode(1)
        }
    }

    internal func describeDataCorruptionError(
        _ context: DecodingError.Context, _ filename: String) {
        if context.underlyingError is DeserializationError {
            switch context.underlyingError as! DeserializationError {
            case .structural(let desc):
                print("""
oa: Syntax error at line \(desc.line), column \(desc.column) of \(filename): \(desc.text)
""", to: &standardError)
            case .value(let desc):
                print("""
oa: Syntax error in value on line \(desc.line) of \(filename): \(desc.text)
""", to: &standardError)
            case .conflictingValue(let desc):
                print("""
oa: Value set twice in \(filename) at line \(desc.line), column \(desc.column): \(desc.text)
""", to: &standardError)
            case .general(let desc):
                print("""
oa: Syntax error at line \(desc.line), column \(desc.column) of \(filename): \(desc.text)
""", to: &standardError)
            case .compound(let errors):
                for error in errors {
                    print("oa: \(error)", to: &standardError)
                }
            }
        } else {
            print("oa: data corruption in \(filename): \(context)",
                  to: &standardError)
        }
    }

    /// Defines the app name and explanatory text for the help screen.
    internal static let configuration = CommandConfiguration(
        commandName: "oa",
        abstract: "(o)pen (a)pplication -- launch apps from the command line.",
        discussion: """
          Pass in the names of apps and `oa' will try to launch each of them.
          It succeeds if they all launch successfully.
          Alternately, you can use `oa' to find out where apps are on the filesystem, or to reveal them in the Finder, instead of launching them.
          """)

    /// The operation the user would like to perform on the given apps.
    @Flag internal var operation: Operation = .launch

    /// If non-`nil`, suppress all printed output.
    @Flag(name: .shortAndLong, help: "Suppress all output.")
    internal var quiet: Bool = false

    /// The apps to operate on.
    @Argument(help: ArgumentHelp(
                  "An application.",
                  discussion: "You must provide at least one.",
                  valueName: "app"))
    internal var apps: [String] = []

    /// Do the provided command line arguments make any sense?
    internal mutating func validate() throws {
        guard !apps.isEmpty else {
            throw ValidationError(
                "You must specify at least one app.")
        }
    }

    /**
     Log a LocationServices error.

     - Parameter result: The status code to log.
     - Parameter app: The app in question.
     */
    private func fail(withErrorCode result: OSStatus, forApp app: String)
      -> ExitCode {

        if !quiet {
            let message = switch result {
            case kLSAppInTrashErr:
                "'\(app)' is in the Trash."
            case kLSNotAnApplicationErr:
                "\(app) is not an app."
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
            print("oa: " + message, to: &standardError)
        }

        return ExitCode(result)
    }
}

extension Operation {
    public static func name(for value: Self) -> NameSpecification {
        return switch value {
        case .locate: .customShort("d") // 'd' for 'directory'
        default: .short
        }
    }

    public static func help(for value: Self) -> ArgumentHelp? {
        return switch value {
        case .launch: ArgumentHelp(
                          "Launch each app.", visibility: .private)
        case .locate: "Print the filesystem paths to each app."
        case .reveal: "Reveal each app in Finder."
        }
    }

    fileprivate func announce(_ appURL: URL) {
        let label = switch self {
        case .launch: "Launching "
        case .reveal: "Revealing "
        default: ""
        }
        print("\(label)\(appURL.path)")
    }
}

/// A TextOutputStream that writes to stderr.
private struct StandardError: TextOutputStream {
    /// Write to stderr.
    fileprivate mutating func write(_ string: String) {
        fputs(string, stderr)
    }
}

/// An instance of `StandardError`.
private var standardError = StandardError()

OpenApp.main()
