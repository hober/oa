#if os(macOS)
import Foundation
typealias ErrorCode = OSStatus
#elseif os(Linux)
typealias ErrorCode = Int32
#elseif os(Windows)
typealias ErrorCode = HRESULT
#endif

protocol AppLauncher {
    init(_ apps: [String], withConfig config: Config, quietly quiet: Bool) throws
    func launchApps() throws
    func locateApps() throws
    func revealApps() throws
}

enum LauncherError: Error, CustomStringConvertible {
    case commandNotFound(String)
    case missingFileManager(String)
    case platformError(ErrorCode, any CustomStringConvertible)
    case unknown((any Error)?)

    var description: String {
        switch self {
        case .commandNotFound(let app):
            return "command not found: \(app)"
        case .missingFileManager(let fileManager):
            return "file manager not found: \(fileManager)"
        case .platformError(_, let underlying):
            return underlying.description
        case .unknown(let underlying):
            return "an unknown error occurred: \(String(describing: underlying))"
        }
    }
}
