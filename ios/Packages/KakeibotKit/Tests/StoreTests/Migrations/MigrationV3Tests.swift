import Core
import GRDB
@testable import Store
import Testing

struct MigrationV3Tests {
    @Test
    func acceptsGlyphsAddedAfterV2() throws {
        let queue = try DatabaseQueue()
        let migrator = AppDatabase.migrator
        try migrator.migrate(queue, upTo: "v2")

        try queue.write { db in
            try db.execute(
                sql: Self.insertIcon,
                arguments: [Self.foodIcon, "food"]
            )
        }

        #expect(throws: DatabaseError.self) {
            try queue.write { db in
                try db.execute(
                    sql: Self.insertIcon,
                    arguments: [Self.cafeIcon, "cafe"]
                )
            }
        }

        try migrator.migrate(queue)

        try queue.write { db in
            try db.execute(
                sql: Self.insertIcon,
                arguments: [Self.cafeIcon, "cafe"]
            )
        }

        let food = try queue.read { db in
            try Icon.fetchOne(db, key: Self.foodIcon)
        }

        let cafe = try queue.read { db in
            try Icon.fetchOne(db, key: Self.cafeIcon)
        }

        #expect(food?.glyph == .food)
        #expect(cafe?.glyph == .cafe)
    }
}

private extension MigrationV3Tests {
    static let foodIcon = "10000000-0000-4000-8000-000000000001"
    static let cafeIcon = "10000000-0000-4000-8000-000000000002"

    static let insertIcon = """
    INSERT INTO icon (id, glyph, color, created_at, updated_at)
    VALUES (?, ?, '#000000', '2026-10-12T00:00:00Z', '2026-10-12T00:00:00Z')
    """
}
