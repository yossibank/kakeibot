import Foundation

enum Fixture {
    static func load<Value: Decodable>(
        _ path: String,
        as type: Value.Type = Value.self
    ) throws -> Value {
        let data = try Data(contentsOf: root.appending(path: path))

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(type, from: data)
    }

    private static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../spec/fixtures")
        .standardized
}

struct ValidityFixture: Decodable {
    let valid: [String]
    let invalid: [String]
}
