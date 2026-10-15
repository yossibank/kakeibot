import Core
import Foundation
import Testing

struct EntryTemplateDraftTests {
    @Test(arguments: try draftCases)
    func findsProblems(fixture: DraftCase) {
        let draft = fixture.draft()
        #expect(draft.problems == fixture.problems)
    }

    @Test
    func makesTemplateWithTrimmedText() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        var draft = Self.lunchDraft()
        draft.name = " ランチ "
        draft.memo = "  "

        let template = try draft.newTemplate(sortOrder: 2, at: now)

        #expect(template.name == "ランチ")
        #expect(template.memo == nil)
        #expect(template.sortOrder == 2)
        #expect(template.createdAt == now)
    }

    @Test
    func keepsIdentityWhenApplied() throws {
        let created = Date(timeIntervalSince1970: 1_790_000_000)
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let original = try Self.lunchDraft().newTemplate(
            sortOrder: 3,
            at: created
        )

        var draft = EntryTemplateDraft(original)
        draft.amount = nil

        let updated = try draft.applied(to: original, at: now)

        #expect(updated.id == original.id)
        #expect(updated.amount == nil)
        #expect(updated.sortOrder == 3)
        #expect(updated.createdAt == created)
        #expect(updated.updatedAt == now)
    }

    @Test
    func makesEntryDraftOnlyWithAmount() throws {
        let date = try #require(LocalDate("2026-10-15"))
        let lunch = try Self.lunchDraft().newTemplate(sortOrder: 0, at: Date())
        var noAmount = lunch
        noAmount.amount = nil

        let draft = lunch.entryDraft(on: date)

        #expect(draft?.amount == 980)
        #expect(draft?.date == date)
        #expect(draft?.memo == "社食")
        #expect(noAmount.entryDraft(on: date) == nil)
    }
}

extension EntryTemplateDraftTests {
    struct DraftCase: Decodable, Sendable {
        let name: String
        let type: Entry.Kind
        let amount: Int?
        let category: Bool
        let wallet: Bool
        let problems: [EntryTemplateDraft.Problem]
    }
}

extension EntryTemplateDraftTests.DraftCase {
    func draft() -> EntryTemplateDraft {
        let categoryId = category ? EntryCategory.ID() : nil
        let walletId = wallet ? Wallet.ID() : nil

        return EntryTemplateDraft(
            name: name,
            type: type,
            amount: amount,
            categoryId: categoryId,
            walletId: walletId
        )
    }
}

private extension EntryTemplateDraftTests {
    static var draftCases: [DraftCase] {
        get throws {
            try Fixture.load("entry/entry-template-draft.json")
        }
    }

    static func lunchDraft() -> EntryTemplateDraft {
        EntryTemplateDraft(
            name: "ランチ",
            type: .expense,
            amount: 980,
            categoryId: EntryCategory.ID(),
            walletId: Wallet.ID(),
            memo: "社食"
        )
    }
}
