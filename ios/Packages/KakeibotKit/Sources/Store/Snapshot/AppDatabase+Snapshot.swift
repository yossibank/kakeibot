import Core
import GRDB

public extension AppDatabase {
    func snapshot() throws -> ExportV1.Tables {
        try writer.read { db in
            try ExportV1.Tables(fetchingFrom: db)
        }
    }

    func replace(with tables: ExportV1.Tables) throws {
        try writer.write { db in
            try ExportV1.Tables.deleteAll(in: db)
            try tables.insert(into: db)
        }
    }
}
