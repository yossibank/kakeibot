import Core
import Foundation
import Testing

struct EntryDraftTests {
    @Test(arguments: try draftCases)
    func findsProblems(fixture: DraftCase) throws {
        let draft = try fixture.draft()
        #expect(draft.problems == fixture.problems)
    }

    @Test
    func makesNewEntryWithTrimmedMemo() throws {
        var draft = try Self.expenseDraft()
        draft.memo = "  ランチ \n"
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let entry = try draft.newEntry(at: now)

        #expect(entry.memo == "ランチ")
        #expect(entry.createdAt == now)
        #expect(entry.updatedAt == now)
    }

    @Test
    func dropsBlankMemoAndDestinationOutsideTransfer() throws {
        var draft = try Self.expenseDraft()
        draft.memo = "   "
        draft.toWalletId = Wallet.ID()

        let entry = try draft.newEntry(at: Date())

        #expect(entry.memo == nil)
        #expect(entry.toWalletId == nil)
    }

    @Test
    func keepsCreationAndRecurringWhenApplied() throws {
        let created = Date(timeIntervalSince1970: 1_790_000_000)
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let recurringDate = try #require(LocalDate("2026-09-27"))
        let recurringId = Recurring.ID()
        let draft = try Self.expenseDraft()

        let original = Entry(
            type: .income,
            amount: 1,
            date: recurringDate,
            categoryId: draft.categoryId,
            walletId: draft.walletId,
            recurringId: recurringId,
            recurringDate: recurringDate,
            createdAt: created,
            updatedAt: created
        )

        let updated = try draft.applied(to: original, at: now)

        #expect(updated.id == original.id)
        #expect(updated.type == .expense)
        #expect(updated.amount == draft.amount)
        #expect(updated.recurringId == recurringId)
        #expect(updated.createdAt == created)
        #expect(updated.updatedAt == now)
    }

    @Test
    func throwsFirstProblem() throws {
        var draft = try Self.expenseDraft()
        draft.amount = 0
        draft.categoryId = nil

        #expect(throws: EntryDraft.Problem.amountNotPositive) {
            try draft.newEntry(at: Date())
        }
    }
}

extension EntryDraftTests {
    struct DraftCase: Decodable, Sendable {
        let type: Entry.Kind
        let amount: Int
        let category: Bool
        let tag: Bool
        let toWallet: Destination
        let problems: [EntryDraft.Problem]
    }

    enum Destination: String, Decodable, Sendable {
        case none
        case same
        case other
    }
}

extension EntryDraftTests.DraftCase {
    func draft() throws -> EntryDraft {
        let walletId = Wallet.ID()
        let date = try #require(LocalDate("2026-10-01"))
        let categoryId = category ? EntryCategory.ID() : nil
        let tagId = tag ? EntryTag.ID() : nil
        let toWalletId = toWallet.walletId(from: walletId)

        return EntryDraft(
            type: type,
            amount: amount,
            date: date,
            categoryId: categoryId,
            tagId: tagId,
            walletId: walletId,
            toWalletId: toWalletId
        )
    }
}

extension EntryDraftTests.Destination {
    func walletId(from source: Wallet.ID) -> Wallet.ID? {
        switch self {
        case .none: nil
        case .same: source
        case .other: Wallet.ID()
        }
    }
}

private extension EntryDraftTests {
    static var draftCases: [DraftCase] {
        get throws {
            try Fixture.load("entry/entry-draft.json")
        }
    }

    static func expenseDraft() throws -> EntryDraft {
        let date = try #require(LocalDate("2026-10-01"))

        return EntryDraft(
            type: .expense,
            amount: 980,
            date: date,
            categoryId: EntryCategory.ID(),
            walletId: Wallet.ID()
        )
    }
}
