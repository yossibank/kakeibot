import Foundation

enum CoreFixture {
    private static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../spec/fixtures")
        .standardized

    static func data(_ path: String) throws -> Data {
        let url = root.appending(path: path)
        return try Data(contentsOf: url)
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

private struct Cases<Case: Decodable>: Decodable {
    let cases: [Case]
}

struct ValidityFixture<Value: Decodable & Sendable>: Decodable {
    let valid: [Value]
    let invalid: [Value]
}
