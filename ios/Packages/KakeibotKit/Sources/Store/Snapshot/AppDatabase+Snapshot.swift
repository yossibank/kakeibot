import Core
import Foundation
import GRDB

public extension AppDatabase {
    func snapshot() throws -> ExportV1.Tables {
        try writer.read { db in
            try ExportV1.Tables(fetchingFrom: db)
        }
    }

    func replace(with tables: ExportV1.Tables) throws {
        try writer.write { db in
            try Self.replace(with: tables, in: db)
        }
    }

    func backup(
        at date: Date,
        app: ExportV1.App
    ) async throws -> Data {
        let tables = try await tables()
        let export = ExportV1(exportedAt: date, app: app, data: tables)
        return try export.json()
    }

    func spreadsheet() async throws -> Data {
        try await tables().csv()
    }

    func restoreBackup(_ export: ExportV1) async throws {
        try await writer.write { db in
            try Self.replace(with: export.data, in: db)
        }
    }
}

private extension AppDatabase {
    func tables() async throws -> ExportV1.Tables {
        try await writer.read { db in
            try ExportV1.Tables(fetchingFrom: db)
        }
    }

    static func replace(
        with tables: ExportV1.Tables,
        in db: Database
    ) throws {
        try ExportV1.Tables.deleteAll(in: db)
        try tables.insert(into: db)
    }
}
