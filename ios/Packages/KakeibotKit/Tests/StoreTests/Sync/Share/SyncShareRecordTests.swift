import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncShareRecordTests {
    @Test
    func sharedEntryFromTemplateNeverArrivesOnPartner() async throws {
        let partner = try await SyncTests.Setup(enabled: false)
        let walletID = try await partner.walletID()
        let categoryID = try await partner.categoryID()

        try await partner.joinForeignShare(of: walletID)

        let zone = try SyncZone.wallet(#require(Wallet.ID(walletID)))
        let key = SyncKey(table: .entry, id: "shared-entry")

        let record = SyncRecord(key: key, values: [
            "id": .text("shared-entry"),
            "type": .text("expense"),
            "amount": .integer(500),
            "date": .text("2026-10-12"),
            "category_id": .text(categoryID),
            "wallet_id": .text(walletID),
            "template_id": .text("template-only-on-inviter"),
            "created_at": .text("2026-10-12T00:00:00Z"),
            "updated_at": .text("2026-10-12T00:00:00Z")
        ])

        try await partner.database.applySyncChanges(
            saved: [record],
            deleted: [],
            systemFields: [key.recordID(in: zone): Data([1])]
        )

        let waiting = try await partner.value("SELECT COUNT(*) FROM sync_waiting")

        #expect(try await partner.database.syncRecord(for: key) != nil)
        #expect(waiting == "0")
    }

    @Test
    func sendsSharedEntryWithoutTemplateAndRecurring() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let entry = try await setup.insertRecurringEntry(wallet: walletID)

        try await setup.database.startSharing(id)

        let shared = try await setup.database
            .syncRecord(for: entry.recordID(in: SyncZone.wallet(id)))
        let own = try await setup.database.syncRecord(for: entry.own)

        #expect(shared?.values["template_id"] == nil)
        #expect(shared?.values["recurring_id"] == nil)
        #expect(shared?.values["recurring_date"] == nil)
        #expect(own?.values["recurring_id"] == .text("r1"))
    }

    @Test
    func keepsLocalRecurringWhenSharedEntryArrives() async throws {
        let setup = try await SyncTests.Setup(enabled: false)
        let walletID = try await setup.walletID()
        let id = try #require(Wallet.ID(walletID))
        let zone = SyncZone.wallet(id)
        let entry = try await setup.insertRecurringEntry(wallet: walletID)

        try await setup.database.startSharing(id)

        let sent = try #require(try await setup.database.syncRecord(for: entry.recordID(in: zone)))
        var values = sent.values
        values["amount"] = .integer(2000)
        values["recurring_id"] = .null
        values["recurring_date"] = .null
        values["updated_at"] = .text("y")

        try await setup.database.applySyncChanges(
            saved: [SyncRecord(key: entry, values: values)],
            deleted: [],
            systemFields: [entry.recordID(in: zone): Data([1])]
        )

        let local = try await setup.database.syncRecord(for: entry)

        #expect(local?.values["amount"] == .integer(2000))
        #expect(local?.values["recurring_id"] == .text("r1"))
        #expect(local?.values["recurring_date"] == .text("2026-10-01"))
    }
}

extension SyncTests.Setup {
    func insertRecurringEntry(wallet walletID: String) async throws -> SyncKey {
        let categoryID = try await categoryID()

        try await execute("""
        INSERT INTO recurring (id, type, amount, category_id, wallet_id, frequency, day, start_date, created_at, updated_at)
        VALUES ('r1', 'expense', 1000, '\(categoryID)', '\(walletID)', 'monthly', 1, '2026-10-01', 'x', 'x')
        """)

        try await execute("""
        INSERT INTO entry (id, type, amount, category_id, wallet_id, date, recurring_id, recurring_date, created_at, updated_at)
        VALUES ('e1', 'expense', 1000, '\(categoryID)', '\(walletID)', '2026-10-01', 'r1', '2026-10-01', 'x', 'x')
        """)

        return SyncKey(table: .entry, id: "e1")
    }
}
