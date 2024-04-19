import Foundation

/* fileprivate */ import TOMLDecoder

/// Describes an error encountered while reading the user's config file.
internal struct ConfigFileError: Error, CustomStringConvertible {
    let description: String
}

/// User-defined app name aliases (e.g. "excel" for "Microsoft Excel").
internal typealias Aliases = [String: String]

/// A struct representing the contents of the user's `oa` config file.
internal struct Config: Codable {
    let linuxFileManager: String?

    /// App aliases for things that are too long to type out by hand.
    let aliases: Aliases
}

extension OpenApp {
    /**
     Load the user's dotfile.
     - Parameter filename: path to the user's config file.
     - Returns: App name aliases defined in the user's config file.
     - Throws: Throws a ``ConfigFileError`` if it had trouble parsing the user's config file.
     */
    internal func loadUserConfig(from filename: String = "~/.oarc") throws -> Config {
        do {
            let contents = try Data(
                contentsOf: URL(
                    fileURLWithPath:
                      NSString(string: filename).expandingTildeInPath))
            let decoder = TOMLDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Config.self, from: contents)
        } catch let error as NSError where error.code == 260 {
            // Missing config file is OK; you don't have to have one.
            return Config(
                linuxFileManager: defaultLinuxFileManager,
                aliases: [:])
        } catch DecodingError.dataCorrupted(let context) {
            throw ConfigFileError(
                description: describeDataCorruptionError(context, filename))
        } catch DecodingError.keyNotFound(let key, _) {
            throw ConfigFileError(
                description: "\(filename) is missing an [\(key.stringValue)] section.")
        } catch DecodingError.typeMismatch(let type, let context) {
            let path = (context.codingPath.map { $0.stringValue }).joined(
                separator: ".")
            throw ConfigFileError(
                description: "Type mismatch at \(path) in \(filename): \(type)")
        } catch DecodingError.valueNotFound(let type, let context) {
            let path = (context.codingPath.map { $0.stringValue }).joined(
                separator: ".")
            throw ConfigFileError(
                description: "\(path) is not a \(type) in \(filename)!")
        } catch {
            throw ConfigFileError(description: "\(error)")
        }
    }
}

fileprivate func describeDataCorruptionError(
    _ context: DecodingError.Context, _ filename: String) -> String {

    guard context.underlyingError is DeserializationError else {
        return "data corruption in \(filename): \(context)"
    }

    return switch context.underlyingError as! DeserializationError {
    case .value(let desc):
        "Syntax error in value on line \(desc.line) of \(filename): \(desc.text)"
    case .conflictingValue(let desc):
        "Value set twice in \(filename) at line \(desc.line), column \(desc.column): \(desc.text)"
    case .structural(let desc), .general(let desc):
        "Syntax error at line \(desc.line), column \(desc.column) of \(filename): \(desc.text)"
    case .compound(let errors):
        errors.map { String(describing: $0) }.joined(separator: "@@@")
    }
}
