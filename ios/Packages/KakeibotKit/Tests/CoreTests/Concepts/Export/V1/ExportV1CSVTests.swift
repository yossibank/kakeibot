import Core
import Foundation
import Testing

struct ExportV1CSVTests {
    @Test
    func writesFixtureRows() throws {
        let json = try CoreFixture.data("export/export-v1.json")
        let expected = try CoreFixture.data("export/export-v1.csv")
        let csv = try ExportV1(json: json).data.csv()
        #expect(csv == expected)
    }

    @Test
    func quotesFieldsWithCommasAndQuotes() throws {
        let json = try CoreFixture.data("export/export-v1.json")
        var tables = try ExportV1(json: json).data
        tables.entries = [tables.entries[0]]
        tables.entries[0].memo = "本, \"上巻\""

        let data = tables.csv()
        let csv = String(decoding: data, as: UTF8.self)
        let lines = csv.components(separatedBy: "\r\n")

        #expect(lines[1].hasSuffix(",\"本, \"\"上巻\"\"\""))
    }

    @Test(arguments: ["1行目\n2行目", "1行目\r2行目", "1行目\r\n2行目"])
    func quotesFieldsWithLineBreaks(memo: String) throws {
        let json = try CoreFixture.data("export/export-v1.json")
        var tables = try ExportV1(json: json).data
        tables.entries = [tables.entries[0]]
        tables.entries[0].memo = memo

        let data = tables.csv()
        let csv = String(decoding: data, as: UTF8.self)

        #expect(csv.hasSuffix(",\"\(memo)\"\r\n"))
    }

    @Test
    func prefixesMemoStartingWithMinus() throws {
        let json = try CoreFixture.data("export/export-v1.json")
        var tables = try ExportV1(json: json).data
        tables.entries = [tables.entries[0]]
        tables.entries[0].memo = "-1"

        let data = tables.csv()
        let csv = String(decoding: data, as: UTF8.self)
        let lines = csv.components(separatedBy: "\r\n")

        #expect(lines[1].hasSuffix(",'-1"))
    }
}
