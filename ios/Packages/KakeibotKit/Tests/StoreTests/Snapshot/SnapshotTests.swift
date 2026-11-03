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
    func skipsUnknownSettingKeys() throws {
        let database = try AppDatabase.inMemory()
        let export = try Self.export

        try database.replace(with: export.data)

        try database.writer.write { db in
            try db.execute(sql: "INSERT INTO setting (key, value) VALUES ('future_key', '1')")
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
        try await restored.restoreBackup(backup, stashingAt: date, app: app) { _ in }

        #expect(backup.exportedAt == date)
        #expect(backup.app == app)
        #expect(try restored.snapshot() == export.data)
    }

    @Test
    func stashesDatabaseInsideTheSameWrite() async throws {
        let database = try AppDatabase.inMemory()
        let sample = try RecordTests.Sample()
        let export = try Self.export
        let date = Date(timeIntervalSince1970: 1_791_000_000)
        let app = ExportV1.App(platform: .ios, version: "1.0")
        let stashed = Stashed()

        try await database.writer.write { db in
            try sample.insert(into: db)
        }

        let before = try database.snapshot()

        try await database.restoreBackup(export, stashingAt: date, app: app) { data in
            stashed.set(data)
        }

        let data = try #require(stashed.data)

        #expect(try ExportV1(json: data).data == before)
        #expect(try database.snapshot() == export.data)
    }

    @Test
    func keepsRowsWhenStashFails() async throws {
        let database = try AppDatabase.inMemory()
        let sample = try RecordTests.Sample()
        let export = try Self.export
        let app = ExportV1.App(platform: .ios, version: "1.0")

        try await database.writer.write { db in
            try sample.insert(into: db)
        }

        let before = try database.snapshot()

        await #expect(throws: StashError.self) {
            try await database.restoreBackup(export, stashingAt: Date(), app: app) { _ in
                throw StashError()
            }
        }

        #expect(try database.snapshot() == before)
    }
}

extension SnapshotTests {
    struct StashError: Error {}

    final class Stashed: @unchecked Sendable {
        private(set) var data: Data?
    }
}

extension SnapshotTests.Stashed {
    func set(_ data: Data) {
        self.data = data
    }
}

private extension SnapshotTests {
    static var export: ExportV1 {
        get throws {
            let json = try StoreFixture.data("export/export-v1.json")
            return try ExportV1(json: json)
        }
    }
}
