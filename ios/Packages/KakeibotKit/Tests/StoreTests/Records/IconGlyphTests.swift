import Core
import Foundation
import GRDB
import Store
import Testing

struct IconGlyphTests {
    @Test
    func readsGlyphAddedByNewerVersionAsDefault() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)

        try await database.writer.write { db in
            try db.execute(sql: "UPDATE icon SET glyph = 'glyph-from-newer-version'")
        }

        let list = try await database.entryList()

        #expect(!list.icons.isEmpty)
        #expect(list.icons.values.allSatisfy { $0.glyph == .other })
    }

    @Test
    func decodesUnknownGlyphInJSONAsDefault() throws {
        let json = Data(#""glyph-from-newer-version""#.utf8)

        let glyph = try JSONDecoder().decode(Icon.Glyph.self, from: json)

        #expect(glyph == .other)
    }
}
