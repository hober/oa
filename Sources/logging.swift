#if os(macOS)
/* fileprivate */ import Darwin
#elseif os(Linux)
/* fileprivate */ import Glibc
#elseif os(Windows)
/* fileprivate */ import CRT
#endif

fileprivate struct StandardError: TextOutputStream {
    mutating func write(_ string: String) {
        fputs(string, stderr)
    }
    static var shared = StandardError()
}

/**
 Log an error.

 Logs `error` to stderr.
 */
internal func log(error: Error) {
    let bin = OpenApp.configuration.commandName ?? "oa"
    let message = String(describing: error)
    print("\(bin): \(message)", to: &StandardError.shared)
}
