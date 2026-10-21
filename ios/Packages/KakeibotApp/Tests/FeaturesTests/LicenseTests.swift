import Features
import Foundation
import Testing

struct LicenseTests {
    @Test
    func readsLicensePlistOutput() throws {
        let bundle = try Self.makeBundle()

        let licenses = License.load(in: bundle)

        #expect(licenses.map(\.title) == ["GRDB.swift (7.11.1)", "Klee One"])
        #expect(licenses.map(\.text) == ["MIT text", "OFL text"])
        #expect(licenses.first?.source?.absoluteString == Self.grdbSource)
        #expect(licenses.last?.source == nil)
    }

    @Test
    func returnsNothingWithoutIndex() {
        let empty = FileManager.default
            .temporaryDirectory
            .appending(path: UUID().uuidString)

        #expect(License.load(in: empty).isEmpty)
    }
}

private extension LicenseTests {
    static func makeBundle() throws -> URL {
        let bundle = FileManager.default
            .temporaryDirectory
            .appending(path: UUID().uuidString)
            .appending(path: "Licenses.bundle")

        let folder = bundle.appending(path: "com.mono0926.LicensePlist")

        try FileManager.default.createDirectory(
            at: folder,
            withIntermediateDirectories: true
        )

        let index: [String: Any] = [
            "PreferenceSpecifiers": [
                ["Title": "Licenses", "Type": "PSGroupSpecifier"],
                child("GRDB.swift", title: "GRDB.swift (7.11.1)"),
                child("Klee One", title: "Klee One")
            ]
        ]

        try write(
            index,
            to: bundle.appending(path: "com.mono0926.LicensePlist.plist")
        )

        try write(
            page("MIT text", source: grdbSource),
            to: folder.appending(path: "GRDB.swift.plist")
        )

        try write(
            page("OFL text"),
            to: folder.appending(path: "Klee One.plist")
        )

        return bundle
    }

    static func child(
        _ file: String,
        title: String
    ) -> [String: Any] {
        [
            "File": "com.mono0926.LicensePlist/\(file)",
            "Title": title,
            "Type": "PSChildPaneSpecifier"
        ]
    }

    static let grdbSource = "https://github.com/groue/GRDB.swift"

    static func page(
        _ text: String,
        source: String? = nil
    ) -> [String: Any] {
        let sourceItems: [[String: Any]] = source.map { url in
            [["Title": "Source", "DefaultValue": url]]
        } ?? []

        return ["PreferenceSpecifiers": sourceItems + [["FooterText": text]]]
    }

    static func write(
        _ plist: [String: Any],
        to url: URL
    ) throws {
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )

        try data.write(to: url)
    }
}
