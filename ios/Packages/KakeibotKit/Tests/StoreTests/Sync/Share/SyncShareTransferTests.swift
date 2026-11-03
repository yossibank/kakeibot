import Core
import Foundation
import GRDB
@testable import Store
import Testing

struct SyncShareTransferTests {
    @Test
    func partnerSeesInviterTransferAsIncome() async throws {
        let partner = try await SyncTests.Setup(enabled: false)
        let walletID = try await partner.walletID()
        let zone = try SyncZone.wallet(#require(Wallet.ID(walletID)))
        let key = SyncKey(table: .entry, id: "transfer")

        try await partner.joinForeignShare(of: walletID)

        let record = SyncRecord(key: key, values: [
            "id": .text("transfer"),
            "type": .text("transfer"),
            "amount": .integer(3000),
            "date": .text("2026-10-12"),
            "category_id": .null,
            "wallet_id": .text("22222222-2222-4222-8222-222222222222"),
            "to_wallet_id": .text(walletID),
            "created_at": .text("2026-10-12T00:00:00Z"),
            "updated_at": .text("2026-10-12T00:00:00Z")
        ])

        try await partner.database.applySyncChanges(
            saved: [record],
            deleted: [],
            systemFields: [key.recordID(in: zone): Data([1])]
        )

        let entry = try await partner.database.syncRecord(for: key)
        let category = try await partner.transferCategory(of: entry)
        let waiting = try await partner.value("SELECT COUNT(*) FROM sync_waiting")

        #expect(entry?.values["type"] == .text("income"))
        #expect(entry?.values["wallet_id"] == .text(walletID))
        #expect(entry?.values["to_wallet_id"] == .null)
        #expect(category == "振替/\(walletID)")
        #expect(waiting == "0")
    }

    @Test
    func partnerSendsOwnTransferAsExpense() async throws {
        let partner = try await SyncTests.Setup(enabled: false)
        let walletID = try await partner.walletID()
        let id = try #require(Wallet.ID(walletID))
        let other = try #require(try await Wallet.ID(partner.otherWalletID()))

        try await partner.joinForeignShare(of: walletID)

        let draft = try EntryDraft(
            type: .transfer,
            amount: 3000,
            date: #require(LocalDate("2026-10-12")),
            categoryId: nil,
            walletId: id,
            toWalletId: other
        )

        let transfer = try await partner.database.saveEntry(draft, at: Date())
        let key = SyncKey(table: .entry, id: transfer.id.description)
        let sent = try await partner.database.syncRecord(for: key.recordID(in: SyncZone.wallet(id)))
        let local = try await partner.database.syncRecord(for: key)
        let category = try await partner.transferCategory(of: sent)

        #expect(sent?.values["type"] == .text("expense"))
        #expect(sent?.values["to_wallet_id"] == .null)
        #expect(category == "振替/\(walletID)")
        #expect(local?.values["type"] == .text("transfer"))
    }

    @Test
    func inviterKeepsTransferWhenPartnerViewArrives() async throws {
        let inviter = try await SyncTests.Setup(enabled: false)
        let walletID = try await inviter.walletID()
        let id = try #require(Wallet.ID(walletID))
        let other = try #require(try await Wallet.ID(inviter.otherWalletID()))
        let zone = SyncZone.wallet(id)

        try await inviter.database.startSharing(id)

        let draft = try EntryDraft(
            type: .transfer,
            amount: 3000,
            date: #require(LocalDate("2026-10-12")),
            categoryId: nil,
            walletId: other,
            toWalletId: id
        )

        let transfer = try await inviter.database.saveEntry(draft, at: Date())
        let key = SyncKey(table: .entry, id: transfer.id.description)

        try await inviter.execute("""
        INSERT INTO category (id, kind, name, icon_id, sort_order, wallet_id, created_at, updated_at)
        SELECT '33333333-3333-4333-8333-333333333333', 'income', '振替', icon_id, 99, '\(walletID)',
            created_at, updated_at
        FROM category LIMIT 1
        """)

        let sent = try #require(try await inviter.database.syncRecord(for: key.recordID(in: zone)))
        var values = sent.values
        values["type"] = .text("income")
        values["wallet_id"] = .text(walletID)
        values["to_wallet_id"] = .null
        values["category_id"] = .text("33333333-3333-4333-8333-333333333333")
        values["amount"] = .integer(3500)
        values["updated_at"] = .text("2099-01-01T00:00:00.000Z")

        try await inviter.database.applySyncChanges(
            saved: [SyncRecord(key: key, values: values)],
            deleted: [],
            systemFields: [key.recordID(in: zone): Data([1])]
        )

        let local = try await inviter.database.syncRecord(for: key)

        #expect(local?.values["type"] == .text("transfer"))
        #expect(local?.values["wallet_id"] == .text(other.description))
        #expect(local?.values["to_wallet_id"] == .text(walletID))
        #expect(local?.values["amount"] == .integer(3500))
    }
}

extension SyncTests.Setup {
    func transferCategory(of record: SyncRecord?) async throws -> String {
        guard case let .text(id) = record?.values["category_id"] else {
            return ""
        }

        return try await value("SELECT name || '/' || wallet_id FROM category WHERE id = '\(id)'")
    }
}
