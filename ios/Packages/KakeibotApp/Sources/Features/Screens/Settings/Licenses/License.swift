import Foundation

public struct License: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let text: String
}

public extension License {
    static func load(in bundle: URL) -> [License] {
        let index = bundle.appending(path: indexName + ".plist")

        return specifiers(at: index).compactMap { specifier in
            guard
                let file = specifier["File"] as? String,
                let title = specifier["Title"] as? String
            else {
                return nil
            }

            let url = bundle.appending(path: file + ".plist")
            let texts = specifiers(at: url)
                .compactMap { $0["FooterText"] as? String }

            return License(
                id: file,
                title: title,
                text: texts.joined(separator: "\n\n")
            )
        }
    }

    static var bundled: [License] {
        guard let url = Bundle.main.url(
            forResource: "Licenses",
            withExtension: "bundle"
        ) else {
            return []
        }

        return load(in: url)
    }
}

private extension License {
    static let indexName = "com.mono0926.LicensePlist"

    static func specifiers(at url: URL) -> [[String: Any]] {
        guard
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(
                from: data,
                format: nil
            ) as? [String: Any]
        else {
            return []
        }

        return plist["PreferenceSpecifiers"] as? [[String: Any]] ?? []
    }
}
