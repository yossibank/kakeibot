import Core
import Foundation

enum SettingsMenuLink {
    static let appStoreId = "6829072935"
    static let contactForm = "https://docs.google.com/forms/d/e/1FAIpQLSekvR-ZF6d760pAkQmw4lDToo8P5C8mJPYBGQbPRHMx3hH8gg/viewform"
    static let modelEntry = "entry.1282978121"
    static let systemEntry = "entry.885969465"
    static let appEntry = "entry.1211808836"

    static let review =
        URL(string: "https://apps.apple.com/app/id\(appStoreId)?action=write-review")

    static var modelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }

        var info = utsname()
        uname(&info)

        return withUnsafeBytes(of: &info.machine) { bytes in
            String(decoding: bytes.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    static var systemVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let base = "\(version.majorVersion).\(version.minorVersion)"
        return version.patchVersion > 0 ? "\(base).\(version.patchVersion)" : base
    }

    static func contact(
        model: String = modelIdentifier,
        system: String = systemVersion,
        app: String = Bundle.main.shortVersion
    ) -> URL? {
        var components = URLComponents(string: contactForm)

        components?.queryItems = [
            URLQueryItem(name: "usp", value: "pp_url"),
            URLQueryItem(name: modelEntry, value: model),
            URLQueryItem(name: systemEntry, value: system),
            URLQueryItem(name: appEntry, value: app)
        ]

        return components?.url
    }
}
