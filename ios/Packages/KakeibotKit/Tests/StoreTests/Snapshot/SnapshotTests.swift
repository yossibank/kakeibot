import Core
import Foundation
import GRDB
import Store
import Testing

struct SnapshotTests {
    @Test
    func roundTripsFixture() throws {
        let database = try AppDatabase.inMemory()
        let export = try Self.export

        try database.replace(with: export.data)
        let snapshot = try database.snapshot()

        #expect(snapshot == export.data)
    }

    @Test
    func replacesExistingRows() throws {
        let database = try AppDatabase.inMemory()
        let sample = try RecordTests.Sample()
        let export = try Self.export

        try database.writer.write { db in
            try sample.insert(into: db)
        }

        try database.replace(with: export.data)
        let snapshot = try database.snapshot()

        #expect(snapshot == export.data)
    }

    @Test
    func keepsRowsWhenReplaceFails() throws {
        let database = try AppDatabase.inMemory()
        let export = try Self.export
        var invalid = export.data
        invalid.entries[0].amount = 0

        try database.replace(with: export.data)

        #expect(throws: DatabaseError.self) {
            try database.replace(with: invalid)
        }

        let snapshot = try database.snapshot()

        #expect(snapshot == export.data)
    }

    @Test
    func restoresWhatItBacksUp() async throws {
        let database = try AppDatabase.inMemory()
        let restored = try AppDatabase.inMemory()
        let export = try Self.export
        let date = Date(timeIntervalSince1970: 1_791_000_000)
        let app = ExportV1.App(platform: .ios, version: "1.0")

        try database.replace(with: export.data)
        let json = try await database.backup(at: date, app: app)
        let backup = try ExportV1(json: json)
        try await restored.restoreBackup(backup)

        #expect(backup.exportedAt == date)
        #expect(backup.app == app)
        #expect(try restored.snapshot() == export.data)
    }
}

private extension SnapshotTests {
    static var export: ExportV1 {
        get throws {
            let json = try Fixture.data("export/export-v1.json")
            return try ExportV1(json: json)
        }
    }
}
