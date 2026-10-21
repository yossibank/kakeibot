import Foundation

public extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    var buildNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }
}
