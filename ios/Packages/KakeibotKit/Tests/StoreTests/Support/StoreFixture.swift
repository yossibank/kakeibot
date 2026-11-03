import Foundation

enum StoreFixture {
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
