import GRDB

enum MigrationV006 {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "entry") { table in
            table.add(column: "template_id", .text).references("template", onDelete: .setNull)
        }
    }
}
