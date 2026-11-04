import Core
import Foundation
import Testing

struct ExportV1Tests {
    @Test
    func roundTripsFixture() throws {
        let fixture = try CoreFixture.data("export/export-v1.json")

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

    @Test
    func readsRecurringsWithoutHolidayShift() throws {
        let json = try Self.fixtureWithoutHolidayShift()

        let export = try ExportV1(json: json)
        let shifts = export.data.recurrings.map(\.holidayShift)

        #expect(!shifts.isEmpty)
        #expect(shifts.allSatisfy { $0 == .none })
    }

    @Test
    func readsTemplatesAndRecurringsWithoutBillShift() throws {
        let json = try Self.fixture(billShift: nil)

        let export = try ExportV1(json: json)
        let templates = export.data.templates.map(\.billShift)
        let recurrings = export.data.recurrings.map(\.billShift)

        #expect(!templates.isEmpty)
        #expect(!recurrings.isEmpty)
        #expect(templates.allSatisfy { $0 == 0 })
        #expect(recurrings.allSatisfy { $0 == 0 })
    }

    @Test(arguments: [(-1, 0), (5, 2)])
    func clampsBillShiftOutOfRange(shift: Int, expected: Int) throws {
        let json = try Self.fixture(billShift: shift)

        let export = try ExportV1(json: json)
        let templates = export.data.templates.map(\.billShift)
        let recurrings = export.data.recurrings.map(\.billShift)

        #expect(!templates.isEmpty)
        #expect(!recurrings.isEmpty)
        #expect(templates.allSatisfy { $0 == expected })
        #expect(recurrings.allSatisfy { $0 == expected })
    }

    @Test
    func readsWalletsWithoutLoanAmount() throws {
        let json = try Self.fixtureWithoutLoanAmount()

        let export = try ExportV1(json: json)
        let amounts = export.data.wallets.map(\.loanAmount)

        #expect(!amounts.isEmpty)
        #expect(amounts.allSatisfy { $0 == nil })
    }

    @Test
    func readsEntriesWithoutBillMonth() throws {
        let json = try Self.fixtureWithoutBillMonth()

        let export = try ExportV1(json: json)
        let months = export.data.entries.map(\.billMonth)

        #expect(!months.isEmpty)
        #expect(months.allSatisfy { $0 == nil })
    }

    @Test
    func readsEntriesWithoutTaxIncludedAsExclusive() throws {
        let json = try Self.fixture(withoutEntryKey: "taxIncluded")

        let export = try ExportV1(json: json)
        let flags = export.data.entries.map(\.taxIncluded)

        #expect(!flags.isEmpty)
        #expect(flags.allSatisfy { !$0 })
    }

    @Test
    func readsEntriesWithoutTransferId() throws {
        let json = try Self.fixtureWithoutTransferId()

        let export = try ExportV1(json: json)
        let transfers = export.data.entries.map(\.transferId)

        #expect(!transfers.isEmpty)
        #expect(transfers.allSatisfy { $0 == nil })
    }

    @Test
    func rejectsFeeWithoutTransfer() throws {
        let json = try Self.fixtureWithoutTransfer()

        #expect(throws: ExportV1.ReadError.missingTransfer) {
            try ExportV1(json: json)
        }
    }

    @Test
    func skipsSettingsWithUnknownKey() throws {
        let rows = try Self.settingRows
        let settings = rows.valid + rows.invalid
        let json = try Self.fixture(settings: settings)
        let export = try ExportV1(json: json)
        let keys = export.data.settings.map(\.key.rawValue)
        #expect(keys == rows.valid.compactMap { $0["key"] })
    }

    @Test
    func rejectsSettingWithBrokenValue() throws {
        let json = try Self.fixture(settings: [["key": "week_start", "value": 1]])

        #expect(throws: DecodingError.self) {
            try ExportV1(json: json)
        }
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
            try CoreFixture.load("export/export-v1-header.json")
        }
    }

    static var settingRows: ValidityFixture<[String: String]> {
        get throws {
            try CoreFixture.load("export/export-v1-setting.json")
        }
    }

    static func fixture(settings: [Any]) throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        tables["settings"] = settings
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixture(with header: Header) throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])

        object["format"] = header.format
        object["version"] = header.version

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutTemplates() throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
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
        let data = try CoreFixture.data("export/export-v1.json")
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
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        tables["shelfIcons"] = nil
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutArchivedAt() throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
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

    static func fixtureWithoutHolidayShift() throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        let rows = try #require(tables["recurrings"] as? [[String: Any]])

        tables["recurrings"] = rows.map { $0.filter { $0.key != "holidayShift" } }
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixture(billShift: Int?) throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        for key in ["templates", "recurrings"] {
            let rows = try #require(tables[key] as? [[String: Any]])

            tables[key] = rows.map { row in
                var row = row
                row["billShift"] = billShift
                return row
            }
        }

        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutLoanAmount() throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        let rows = try #require(tables["wallets"] as? [[String: Any]])

        tables["wallets"] = rows.map { $0.filter { $0.key != "loanAmount" } }
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutBillMonth() throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        let rows = try #require(tables["entries"] as? [[String: Any]])

        tables["entries"] = rows.map { $0.filter { $0.key != "billMonth" } }
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixture(withoutEntryKey key: String) throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        let rows = try #require(tables["entries"] as? [[String: Any]])

        tables["entries"] = rows.map { $0.filter { $0.key != key } }
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutTransferId() throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        let rows = try #require(tables["entries"] as? [[String: Any]])

        tables["entries"] = rows.map { $0.filter { $0.key != "transferId" } }
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func fixtureWithoutTransfer() throws -> Data {
        let data = try CoreFixture.data("export/export-v1.json")
        let json = try JSONSerialization.jsonObject(with: data)

        var object = try #require(json as? [String: Any])
        var tables = try #require(object["data"] as? [String: Any])

        let rows = try #require(tables["entries"] as? [[String: Any]])

        tables["entries"] = rows.filter { ($0["type"] as? String) != "transfer" }
        object["data"] = tables

        return try JSONSerialization.data(withJSONObject: object)
    }

    static func jsonObject(_ data: Data) throws -> NSDictionary {
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? NSDictionary)
    }
}
