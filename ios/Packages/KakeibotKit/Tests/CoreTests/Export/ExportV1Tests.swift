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

    @Test
    func readsFileWithoutTemplates() throws {
        let json = try Self.fixtureWithoutTemplates()

        let export = try ExportV1(json: json)

        #expect(export.data.templates.isEmpty)
        #expect(!export.data.entries.isEmpty)
        #expect(export.data.entries.allSatisfy { $0.templateId == nil })
    }

    @Test
    func readsFileWithoutTags() throws {
        let json = try Self.fixtureWithoutTags()

        let export = try ExportV1(json: json)

        #expect(export.data.tags.isEmpty)
        #expect(export.data.entries.allSatisfy { $0.tagId == nil })
        #expect(export.data.templates.allSatisfy { $0.tagId == nil })
    }

    @Test
    func readsFileWithoutShelfIcons() throws {
        let json = try Self.fixtureWithoutShelfIcons()

        let export = try ExportV1(json: json)

        #expect(export.data.shelfIcons.isEmpty)
        #expect(!export.data.icons.isEmpty)
    }

    @Test
    func readsTemplatesAndRecurringsWithoutArchivedAt() throws {
        let json = try Self.fixtureWithoutArchivedAt()

        let export = try ExportV1(json: json)

        #expect(!export.data.templates.isEmpty)
        #expect(export.data.templates.allSatisfy { $0.archivedAt == nil })
        #expect(!export.data.recurrings.isEmpty)
        #expect(export.data.recurrings.allSatisfy { $0.archivedAt == nil })
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
        let json = try JSONSerialization.jsonObject(with: data)
        var object = try #require(json as? [String: Any])
        object["format"] = header.format
        object["version"] = header.version
        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutTemplates() throws -> Data {
        let data = try Fixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)
        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])
        tables["templates"] = nil
        let entries = try #require(tables["entries"] as? [[String: Any]])
        tables["entries"] = entries.map { $0.filter { $0.key != "templateId" } }
        object["data"] = tables
        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutTags() throws -> Data {
        let data = try Fixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)
        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])
        tables["tags"] = nil

        for key in ["entries", "templates"] {
            let rows = try #require(tables[key] as? [[String: Any]])
            tables[key] = rows.map { $0.filter { $0.key != "tagId" } }
        }

        object["data"] = tables
        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutShelfIcons() throws -> Data {
        let data = try Fixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)
        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])
        tables["shelfIcons"] = nil
        object["data"] = tables
        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutArchivedAt() throws -> Data {
        let data = try Fixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)
        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        for key in ["templates", "recurrings"] {
            let rows = try #require(tables[key] as? [[String: Any]])
            tables[key] = rows.map { $0.filter { $0.key != "archivedAt" } }
        }

        object["data"] = tables
        return try JSONSerialization.data(withJSONObject: object)
    }

    static func jsonObject(_ data: Data) throws -> NSDictionary {
        try #require(JSONSerialization.jsonObject(with: data) as? NSDictionary)
    }
}
