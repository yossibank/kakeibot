import GRDB

enum MigrationV31 {
    static func migrate(_ db: Database) throws {
        try db.create(index: "entry_date", on: "entry", columns: ["date"])
        try db.create(index: "entry_wallet_id_date", on: "entry", columns: ["wallet_id", "date"])
        try db.create(index: "entry_to_wallet_id", on: "entry", columns: ["to_wallet_id"])
        try db.create(index: "entry_category_id", on: "entry", columns: ["category_id"])
    }
}
