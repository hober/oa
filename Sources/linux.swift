#if os(Linux)

import Foundation

fileprivate let filesep = "/"
fileprivate let pathsep = ":"

/// What file manager to use on Linux by default.
fileprivate let defaultLinuxFileManager = "nautilus"

struct LinuxAppLauncher {
    let apps: [String]
    let fileManager: String
    let quiet: Bool
    var urls: [URL] = []

    init(_ apps: [String], withConfig config: Config, quietly quiet: Bool) throws {
        var fileManager = defaultLinuxFileManager

        // FIXME: trawl XDG_CURRENT_DESKTOP for a sensible fileManager
        // default

        if let platform = config.linux {
            if let manager = platform.fileManager {
                fileManager = manager
            }
        }

        self.apps = apps
        self.fileManager = fileManager
        self.quiet = quiet

        let aliases = config.mergedAliases()

        self.urls = try apps.map {
            try locateLinuxApp(byName: aliases[$0] ?? $0)
        }
    }

    func launchApps() throws {
        for url in urls {
            let process = Process()

            process.executableURL = url
            process.arguments = []
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            try process.run()
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

    func locateLinuxApp(byName appName: String) throws -> URL {
        if let appPath = try pathOfExecutable(named: appName) {
            return URL(fileURLWithPath: appPath)
        }
        throw LauncherError.commandNotFound(appName)
    }

    func revealApps() throws {
        do {
            let fm = try locateLinuxApp(byName: fileManager)

            let process = Process()

            process.executableURL = fm
            process.arguments = urls.map { $0.absoluteString }
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            try process.run()
        } catch LauncherError.commandNotFound {
            throw LauncherError.missingFileManager(fileManager)
        }
    }
}

fileprivate func pathOfExecutable(named executable: String) throws -> String? {
    let path = ProcessInfo.processInfo.environment["PATH"] ?? ""

    for directory in path.components(separatedBy: pathsep) {
        guard FileManager.default.fileExists(atPath: directory) else {
            continue
        }
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory)
            if files.contains(executable) {
                return "\(directory)\(filesep)\(executable)"
            }
        } catch let error as CustomStringConvertible {
            throw LauncherError.platformError(-1, error)
        } catch {
            throw LauncherError.unknown(error)
        }
    }

    return nil
}

#endif
