import Foundation

public enum DeviceName {
    public static let current = name(ofModel: modelIdentifier)

    public static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }

        var info = utsname()

        uname(&info)

        return withUnsafeBytes(of: &info.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    static func name(ofModel model: String) -> String {
        model.hasPrefix("iPad") ? "iPad" : "iPhone"
    }
}
