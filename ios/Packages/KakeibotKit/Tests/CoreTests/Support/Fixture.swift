import Foundation

enum Fixture {
    static func data(_ path: String) throws -> Data {
        try Data(contentsOf: root.appending(path: path))
    }

    static func load<Value: Decodable>(
        _ path: String,
        as type: Value.Type = Value.self
    ) throws -> Value {
        let data = try data(path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }

    static func cases<Case: Decodable>(
        _ path: String,
        as type: Case.Type = Case.self
    ) throws -> [Case] {
        try load(path, as: Cases<Case>.self).cases
    }
}

private extension Fixture {
    static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../spec/fixtures")
        .standardized
}

private struct Cases<Case: Decodable>: Decodable {
    let cases: [Case]
}

struct ValidityFixture<Value: Decodable & Sendable>: Decodable {
    let valid: [Value]
    let invalid: [Value]
}
