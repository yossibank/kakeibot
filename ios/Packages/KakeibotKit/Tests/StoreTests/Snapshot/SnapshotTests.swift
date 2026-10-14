import Core
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
}

private extension SnapshotTests {
    static var export: ExportV1 {
        get throws {
            let json = try Fixture.data("export/export-v1.json")
            return try ExportV1(json: json)
        }
    }
}
