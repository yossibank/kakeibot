import Core
import Foundation
import Testing

extension ExportV1Tests {
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
