import Foundation

enum StoreFixture {
    static let now = Date(timeIntervalSince1970: 1_791_000_000)

    static func data(_ path: String) throws -> Data {
        try Data(contentsOf: root.appending(path: path))
    }
}

private extension StoreFixture {
    static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../spec/fixtures")
        .standardized
}
