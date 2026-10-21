import Core
import Foundation
import Testing

struct ExportV1CSVTests {
    @Test
    func writesFixtureRows() throws {
        let json = try Fixture.data("export/export-v1.json")
        let expected = try Fixture.data("export/export-v1.csv")

        let csv = try ExportV1(json: json).data.csv()

        #expect(csv == expected)
    }

    @Test
    func quotesFieldsWithCommasAndQuotes() throws {
        let json = try Fixture.data("export/export-v1.json")
        var tables = try ExportV1(json: json).data
        tables.entries = [tables.entries[0]]
        tables.entries[0].memo = "本, \"上巻\""

        let csv = String(decoding: tables.csv(), as: UTF8.self)
        let lines = csv.components(separatedBy: "\r\n")

        #expect(lines[1].hasSuffix(",\"本, \"\"上巻\"\"\""))
    }
}
