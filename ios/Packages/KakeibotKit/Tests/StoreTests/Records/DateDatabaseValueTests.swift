import Core
import GRDB
import Store
import Testing

struct DateDatabaseValueTests {
    @Test
    func storesLocalDateAsText() throws {
        let database = try makeDatabase()
        let date = try #require(LocalDate("2026-02-01"))

        try insert(date, into: database)
        let text = try fetch(String.self, from: database)
        let decoded = try fetch(LocalDate.self, from: database)

        #expect(text == "2026-02-01")
        #expect(decoded == date)
    }

    @Test
    func storesYearMonthAsText() throws {
        let database = try makeDatabase()
        let month = try #require(YearMonth("2026-02"))

        try insert(month, into: database)
        let text = try fetch(String.self, from: database)
        let decoded = try fetch(YearMonth.self, from: database)

        #expect(text == "2026-02")
        #expect(decoded == month)
    }

    @Test
    func rejectsInvalidText() throws {
        let database = try makeDatabase()

        try insert("2026-02-30", into: database)

        #expect(throws: (any Error).self) {
            try fetch(LocalDate.self, from: database)
        }
    }
}

private extension DateDatabaseValueTests {
    func makeDatabase() throws -> DatabaseQueue {
        let database = try DatabaseQueue()
        try database.write { db in
            try db.execute(sql: "CREATE TABLE sample (value TEXT)")
        }
        return database
    }

    func insert(
        _ value: some DatabaseValueConvertible,
        into database: DatabaseQueue
    ) throws {
        try database.write { db in
            try db.execute(
                sql: "INSERT INTO sample (value) VALUES (?)",
                arguments: [value]
            )
        }
    }

    func fetch<Value: DatabaseValueConvertible>(
        _ type: Value.Type,
        from database: DatabaseQueue
    ) throws -> Value? {
        try database.read { db in
            try type.fetchOne(db, sql: "SELECT value FROM sample")
        }
    }
}
