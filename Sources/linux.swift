/// What file manager to use on Linux by default.
internal let defaultLinuxFileManager = "nautilus"

#if os(Linux)

import Foundation

fileprivate func pathOfExecutable(named executable: String) throws -> String? {
    let filesep = "/"
    let pathsep = ":"

    let path = ProcessInfo.processInfo.environment["PATH"] ?? ""

    for directory in path.components(separatedBy: pathsep) {
        let files = try FileManager.default.contentsOfDirectory(atPath: directory)
        if files.contains(executable) {
            return "\(directory)\(filesep)\(executable)"
        }
    }

    return nil
}

fileprivate struct CommandNotFound: Error, CustomStringConvertible {
    let command: String

    init(_ command: String) {
        self.command = command
    }

    var description: String {
        return "command not found: \(command)"
    }
}

/**
 Reveal files in the user's file manager.

 - Parameter urls: file:/// URLs to each file to reveal.
 */
internal func reveal(urls: [URL], withConfig config: Config) throws {
    var fileManager = defaultLinuxFileManager

    if let platform = config.linux {
        if let manager = platform.fileManager {
            fileManager = manager
        }
    }

    let process = Process()

    process.executableURL = try locateApp(byName: fileManager)
    process.arguments = urls.map { $0.absoluteString }
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    try process.run()
}

/**
 Return a file URL to the given app.


 - Parameter appName: The name of the app to locate.
 - Returns: a URL to the app.
 - Throws: Throws a ``CommandNotFound`` if the app cannot be found in `$PATH`.
 */
internal func locateApp(byName appName: String) throws -> URL {
    if let appPath = try pathOfExecutable(named: appName) {
        return URL(fileURLWithPath: appPath)
    }

    throw CommandNotFound(appName)
}

/**
 Launch an app.

 - Parameter url: the URL to the app.
 - Parameter appName: A human-readable name of the app.
 - Throws: if the process fails to launch.
 */
internal func launchApp(byURL url: URL, withName appName: String) throws {
    let process = Process()

    process.executableURL = url
    process.arguments = []
    process.standardInput = FileHandle.nullDevice
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice

    try process.run()
}

#endif
