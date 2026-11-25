import Foundation

enum FeaturesFixture {
    private static let root = URL(filePath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "../../../../../../spec/fixtures")
        .standardized

    static func cases<Case: Decodable>(
        _ path: String,
        as type: Case.Type = Case.self
    ) throws -> [Case] {
        let data = try Data(contentsOf: root.appending(path: path))
        return try JSONDecoder().decode(Cases<Case>.self, from: data).cases
    }
}

private struct Cases<Case: Decodable>: Decodable {
    let cases: [Case]
}
