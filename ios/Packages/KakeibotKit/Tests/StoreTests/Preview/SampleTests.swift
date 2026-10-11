#if DEBUG
    import Core
    import Foundation
    import Store
    import Testing

    struct SampleTests {
        @Test
        func writesSampleEntriesWithOneWalletAndCategory() async throws {
            let database = try AppDatabase.inMemory()
            let now = Date(timeIntervalSince1970: 1_791_000_000)
            let today = try #require(LocalDate("2026-10-03"))

            try await database.writeSampleEntries(count: 100, on: today, at: now)
            try await database.writeSampleEntries(count: 50, on: today, at: now)
            let count = try await database.entryCount()
            let snapshot = try database.snapshot()

            #expect(count == 150)
            #expect(snapshot.wallets.count == 1)
            #expect(snapshot.categories.count == 1)
        }
    }
#endif
