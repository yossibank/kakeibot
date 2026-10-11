import Foundation

enum Fixture {}

extension Fixture {
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

private extension Fixture {
    static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../spec/fixtures")
        .standardized
}

struct ValidityFixture<Value: Decodable & Sendable>: Decodable {
    let valid: [Value]
    let invalid: [Value]
}
