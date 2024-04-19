import ArgumentParser

/**
 Operations the user may request to perform on apps.

 Implements the [`EnumerableFlag`](https://swiftpackageindex.com/apple/swift-argument-parser/1.3.1/documentation/argumentparser/enumerableflag) protocol from [`swift-argument-parser`](https://github.com/apple/swift-argument-parser).
 */
internal enum Operation: EnumerableFlag {
    /// Launch the apps.
    case launch
    /// Locate the apps on the filesystem.
    case locate
    /// Reveal the apps in Finder.
    case reveal
}

/**
 Implementation of the `oa` command.

 Implements the [`ParsableCommand`](https://swiftpackageindex.com/apple/swift-argument-parser/1.3.1/documentation/argumentparser/parsablecommand) protocol from [`swift-argument-parser`](https://github.com/apple/swift-argument-parser).
 */
@main
internal struct OpenApp: ParsableCommand {
    @_documentation(visibility: private)
    static let configuration = CommandConfiguration(
        commandName: "oa",
        abstract: "(o)pen (a)pplications -- launch apps from the command line.",
        discussion: "Pass in the names of apps and oa will try to launch each of them. It succeeds if they all launch successfully. Alternately, you can use oa to find out where apps are on the filesystem, or to reveal them in the Finder, instead of launching them.")

    /// The operation to perform on the given apps.
    @Flag var operation: Operation = .launch

    /// If true, suppress all printed output.
    @Flag(name: .shortAndLong, help: "Suppress all output.")
    var quiet: Bool = false

    /// The apps to operate on.
    @Argument(help: ArgumentHelp(
                  "An application.",
                  discussion: "You must provide at least one.", valueName: "app"))
    var apps: [String] = []

    /**
     Do the provided command line arguments make any sense?
     - Throws: a [`ValidationError`](https://swiftpackageindex.com/apple/swift-argument-parser/1.3.1/documentation/argumentparser/validationerror) for the given operation's command-line agument.
     */
    func validate() throws {
        guard !apps.isEmpty else {
            throw ValidationError("You must specify at least one app.")
        }
    }

    /**
     Run the command.
     - Throws: an [`ExitCode`](https://swiftpackageindex.com/apple/swift-argument-parser/1.3.1/documentation/argumentparser/exitcode) if the command should exit with an error.
     */
    func run() throws {
        do {
            let config = try loadUserConfig()

            let urls = try apps.map {
                try locateApp(byName: config.aliases[$0] ?? $0)
            }

            if operation == .reveal {
                try reveal(urls: urls, withConfig: config)
                return
            }

            for (i, url) in urls.enumerated() {
                if !quiet {
                    print(operation.announcement(for: url.path))
                }

                if operation == .launch {
                    do {
                        try launchApp(byURL: url, withName: apps[i])
                    } catch {
                        throw error
                    }
                }
            }
        } catch let dotfileProblem as ConfigFileError {
            // always complain about dotfile syntax errors
            log(error: dotfileProblem)
            throw ExitCode(1)
        } catch {
            if !quiet {
                log(error: error)
            }
            #if os(macOS)
            if let lsError = error as? LaunchServicesError {
                throw ExitCode(lsError.status)
            } else {
                throw ExitCode(2)
            }
            #else
            throw ExitCode(3)
            #endif
        }
    }
}

extension Operation {
    /**
     What should the command-line argument for the given operation be named?
     - Parameter value: the operation.
     - Returns: a [`NameSpecification`](https://swiftpackageindex.com/apple/swift-argument-parser/1.3.1/documentation/argumentparser/namespecification) for the given operation's command-line agument.
     */
    @_documentation(visibility: private)
    static func name(for value: Self) -> NameSpecification {
        return switch value {
        case .launch: .short
        case .locate: .customShort("d") // 'd' for 'directory'
        case .reveal: .short
        }
    }

    /**
     Generate suitable help text for the given operation.
     - Parameter value: the operation.
     - Returns: an [`ArgumentHelp`](https://swiftpackageindex.com/apple/swift-argument-parser/1.3.1/documentation/argumentparser/argumenthelp) for the given operation.
     */
    @_documentation(visibility: private)
    static func help(for value: Self) -> ArgumentHelp? {
        return switch value {
        case .launch: ArgumentHelp("Launch each app.", visibility: .private)
        case .locate: "Print the filesystem paths to each app."
        case .reveal: "Reveal each app in Finder."
        }
    }

    /**
     Generate a human-readable string for applying this operation to the
     given app.
     - Parameter path: a path to an app.
     - Returns: a human-readable string describing this operation as
       applied to the given app.
     */
    @_documentation(visibility: private)
    func announcement(for path: String) -> String {
        let label = switch self {
        case .launch: "Launching "
        case .locate: ""
        case .reveal: "Revealing "
        }
        return label + path
    }
}
