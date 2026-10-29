import Core
import Foundation
import Store
import Testing

struct ValuationWriteTests {
    @Test
    func replacesValuationOnTheSameDay() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let wallet = try #require(options.wallets.first)
        let day = try #require(LocalDate("2026-10-21"))
        let now = Date()
        var investment = wallet
        investment.kind = .investment

        try await database.saveValuation(150_000, of: wallet.id, on: day, at: now)
        try await database.saveValuation(160_000, of: wallet.id, on: day, at: now)
        let list = try await database.entryList()
        let balance = investment.balance(with: [], valuations: list.valuations)

        #expect(list.valuations.map(\.amount) == [160_000])
        #expect(balance == 160_000)
    }

    @Test
    func restoresDeletedValuation() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let wallet = try #require(options.wallets.first)
        let day = try #require(LocalDate("2026-10-21"))
        try await database.saveValuation(150_000, of: wallet.id, on: day, at: Date())
        let saved = try await database.entryList().valuations
        let id = try #require(saved.first?.id)

        let deletion = try #require(try await database.deleteValuation(id))
        let deleted = try await database.entryList().valuations
        try await database.restore(deletion)
        let restored = try await database.entryList().valuations

        #expect(deleted.isEmpty)
        #expect(restored == saved)
    }

    @Test
    func returnsNoDeletionForMissingValuation() async throws {
        let database = try AppDatabase.inMemory()
        try database.insertDefaultsIfEmpty(at: Date())
        let options = try await database.entryOptions()
        let wallet = try #require(options.wallets.first)
        let day = try #require(LocalDate("2026-10-21"))
        try await database.saveValuation(150_000, of: wallet.id, on: day, at: Date())
        let id = try #require(try await database.entryList().valuations.first?.id)
        _ = try await database.deleteValuation(id)

        let deletion = try await database.deleteValuation(id)

        #expect(deletion == nil)
    }
}
