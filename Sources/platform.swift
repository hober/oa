#if os(macOS)
import Foundation
typealias ErrorCode = OSStatus
#elseif os(Linux)
typealias ErrorCode = Int
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
    // ErrorCode needs to be defined in each platform's file
    case platformError(ErrorCode, any CustomStringConvertible)

    var description: String {
        switch self {
        case .commandNotFound(let app):
            return "command not found: \(app)"
        case .platformError(_, let underlying):
            return underlying.description
        }
    }
}
