import Core
import Foundation
import Testing

struct EntryCategoryDraftTests {
    @Test(arguments: try draftCases)
    func findsProblems(fixture: DraftCase) throws {
        let draft = try fixture.draft()
        #expect(draft.problems == fixture.problems)
    }

    @Test
    func makesIconWithOnlyTheChosenMark() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let draft = EntryCategoryDraft(
            kind: .expense,
            name: " 推し ",
            mark: .text(" 推し "),
            color: "#9C6ADE"
        )

        let icon = try draft.newIcon(at: now)
        let category = try draft.newCategory(iconId: icon.id, sortOrder: 12, at: now)

        #expect(icon.text == "推し")
        #expect(icon.emoji == nil)
        #expect(icon.glyph == nil)
        #expect(category.name == "推し")
        #expect(category.iconId == icon.id)
        #expect(category.sortOrder == 12)
    }

    @Test
    func keepsIdentityWhenApplied() throws {
        let created = Date(timeIntervalSince1970: 1_790_000_000)
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let icon = Icon(
            emoji: "🍙",
            text: nil,
            color: "#E07A5F",
            createdAt: created,
            updatedAt: created
        )

        let category = EntryCategory(
            kind: .expense,
            name: "食費",
            iconId: icon.id,
            sortOrder: 3,
            createdAt: created,
            updatedAt: created
        )

        var draft = EntryCategoryDraft(category, icon: icon)
        draft.name = "外食"
        draft.mark = .glyph(.cafe)

        let updatedIcon = try draft.applied(to: icon, at: now)
        let updatedCategory = try draft.applied(to: category, at: now)

        #expect(EntryCategoryDraft.Mark(icon) == .emoji("🍙"))
        #expect(updatedIcon.id == icon.id)
        #expect(updatedIcon.glyph == .cafe)
        #expect(updatedIcon.emoji == nil)
        #expect(updatedIcon.createdAt == created)
        #expect(updatedCategory.id == category.id)
        #expect(updatedCategory.name == "外食")
        #expect(updatedCategory.sortOrder == 3)
        #expect(updatedCategory.updatedAt == now)
    }
}

extension EntryCategoryDraftTests {
    struct DraftCase: Decodable, Sendable {
        let name: String
        let mark: FixtureMark
        let color: String
        let problems: [EntryCategoryDraft.Problem]
    }
}

extension EntryCategoryDraftTests.DraftCase {
    func draft() throws -> EntryCategoryDraft {
        let mark = try mark.mark()
        return EntryCategoryDraft(kind: .expense, name: name, mark: mark, color: color)
    }
}

private extension EntryCategoryDraftTests {
    static var draftCases: [DraftCase] {
        get throws {
            try CoreFixture.cases("category/entry-category-draft.json")
        }
    }
}
