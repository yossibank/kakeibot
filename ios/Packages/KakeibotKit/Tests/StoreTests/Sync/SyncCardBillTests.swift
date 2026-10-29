import Core
import Foundation
@testable import Store
import Testing

struct SyncCardBillTests {
    @Test
    func recalculatesBillForReceivedCardEntries() async throws {
        let setup = try await CardBillRecalcWriteTests.Setup(usage: [10000])
        let key = SyncKey(table: .entry, id: "44444444-4444-4444-8444-444444444444")

        let record = SyncRecord(key: key, values: [
            "id": .text(key.id),
            "type": .text("expense"),
            "amount": .integer(3000),
            "date": .text("2026-10-05"),
            "category_id": .text(setup.category.description),
            "wallet_id": .text(setup.card.description),
            "created_at": .text("2026-10-05T00:00:00Z"),
            "updated_at": .text("2026-10-05T00:00:00Z")
        ])

        try await setup.database.applySyncChanges(saved: [record], deleted: [])
        let added = try setup.bill()?.amount

        try await setup.database.applySyncChanges(saved: [], deleted: [key.own])
        let removed = try setup.bill()?.amount

        #expect(added == 13000)
        #expect(removed == 10000)
    }
}
