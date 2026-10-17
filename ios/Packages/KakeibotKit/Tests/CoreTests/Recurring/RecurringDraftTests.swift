import Core
import Foundation
import Testing

struct RecurringDraftTests {
    @Test(arguments: try draftCases)
    func findsProblems(fixture: DraftCase) {
        let draft = fixture.draft()
        #expect(draft.problems == fixture.problems)
    }

    @Test
    func makesRecurringWithTrimmedMemo() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        var draft = try Self.rentDraft()
        draft.memo = " 家賃 "

        let recurring = try draft.newRecurring(at: now)

        #expect(recurring.memo == "家賃")
        #expect(recurring.month == nil)
        #expect(recurring.generatedUntil == nil)
        #expect(recurring.createdAt == now)
    }

    @Test
    func keepsIdentityWhenApplied() throws {
        let created = Date(timeIntervalSince1970: 1_790_000_000)
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let generated = try #require(LocalDate("2026-03-27"))
        var original = try Self.rentDraft().newRecurring(at: created)
        original.generatedUntil = generated

        var draft = RecurringDraft(original)
        draft.frequency = .yearly
        draft.month = 4

        let updated = try draft.applied(to: original, at: now)

        #expect(updated.id == original.id)
        #expect(updated.month == 4)
        #expect(updated.generatedUntil == generated)
        #expect(updated.createdAt == created)
        #expect(updated.updatedAt == now)
    }
}

extension RecurringDraftTests {
    struct DraftCase: Decodable, Sendable {
        let type: Entry.Kind
        let amount: Int
        let category: Bool
        let wallet: Bool
        let frequency: Recurring.Frequency
        let month: Int
        let day: Int
        let startDate: LocalDate
        let endDate: LocalDate?
        let remindDaysBefore: Int?
        let problems: [RecurringDraft.Problem]

        func draft() -> RecurringDraft {
            RecurringDraft(
                type: type,
                amount: amount,
                categoryId: category ? EntryCategory.ID() : nil,
                walletId: wallet ? Wallet.ID() : nil,
                frequency: frequency,
                month: month,
                day: day,
                startDate: startDate,
                endDate: endDate,
                remindDaysBefore: remindDaysBefore
            )
        }
    }
}

private extension RecurringDraftTests {
    static var draftCases: [DraftCase] {
        get throws {
            try Fixture.load("recurring/recurring-draft.json")
        }
    }

    static func rentDraft() throws -> RecurringDraft {
        let start = try #require(LocalDate("2026-01-01"))

        return RecurringDraft(
            type: .expense,
            amount: 78000,
            categoryId: EntryCategory.ID(),
            walletId: Wallet.ID(),
            frequency: .monthly,
            month: 1,
            day: 27,
            startDate: start
        )
    }
}
