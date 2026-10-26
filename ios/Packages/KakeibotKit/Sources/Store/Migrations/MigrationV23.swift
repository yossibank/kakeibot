import GRDB

enum MigrationV23 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "entry") { table in
            table.add(column: "transfer_id", .text).references("entry", onDelete: .cascade)
        }

        try db.create(
            index: "entry_transfer",
            on: "entry",
            columns: ["transfer_id"],
            options: .unique
        )
    }
}
