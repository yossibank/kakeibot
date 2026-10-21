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

        try await database.saveValuation(
            150_000,
            of: wallet.id,
            on: day,
            at: now
        )

        try await database.saveValuation(
            160_000,
            of: wallet.id,
            on: day,
            at: now
        )

        let list = try await database.entryList()

        let balance = wallet.balance(with: [], valuations: list.valuations)

        #expect(list.valuations.map(\.amount) == [160_000])
        #expect(balance == 160_000)
    }
}
