import Core
import Foundation
import Testing

struct ExportV1Tests {
    @Test
    func roundTripsFixture() throws {
        let fixture = try Fixture.data("export/export-v1.json")

        let export = try ExportV1(json: fixture)
        let written = try export.json()
        let reread = try ExportV1(json: written)

        #expect(try Self.jsonObject(written) == Self.jsonObject(fixture))
        #expect(reread == export)
    }

    @Test(arguments: try headers.valid)
    func readsSupportedHeader(header: Header) throws {
        let json = try Self.fixture(with: header)

        let export = try ExportV1(json: json)

        #expect(export.app.platform == .ios)
    }

    @Test(arguments: try headers.invalid)
    func rejectsUnsupportedHeader(header: Header) throws {
        let json = try Self.fixture(with: header)

        #expect(throws: ExportV1.ReadError.self) {
            try ExportV1(json: json)
        }
    }
}

extension ExportV1Tests {
    struct Header: Decodable, Sendable {
        let format: String
        let version: Int
    }
}

private extension ExportV1Tests {
    static var headers: ValidityFixture<Header> {
        get throws {
            try Fixture.load("export/export-v1-header.json")
        }
    }

    static func fixture(with header: Header) throws -> Data {
        let data = try Fixture.data("export/export-v1.json")
        var object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object["format"] = header.format
        object["version"] = header.version
        return try JSONSerialization.data(withJSONObject: object)
    }

    static func jsonObject(_ data: Data) throws -> NSDictionary {
        try #require(JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }
}
