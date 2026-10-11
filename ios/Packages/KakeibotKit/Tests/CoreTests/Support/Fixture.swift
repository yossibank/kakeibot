import Foundation

enum Fixture {
    private static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../spec/fixtures")
        .standardized

    static func load<Value: Decodable>(
        _ path: String,
        as type: Value.Type = Value.self
    ) throws -> Value {
        let data = try Data(contentsOf: root.appending(path: path))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}

struct ValidityFixture: Decodable {
    let valid: [String]
    let invalid: [String]
}
