import Core
import Foundation
import Testing

struct EntryTagDraftTests {
    @Test(arguments: try draftCases)
    func findsProblems(fixture: DraftCase) {
        let draft = EntryTagDraft(name: fixture.name)
        #expect(draft.problems == fixture.problems)
    }

    @Test
    func makesNewTagWithTrimmedName() throws {
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let categoryId = EntryCategory.ID()
        let draft = EntryTagDraft(name: " 昼ごはん ")

        let tag = try draft.newTag(
            categoryId: categoryId,
            sortOrder: 2,
            at: now
        )

        #expect(tag.name == "昼ごはん")
        #expect(tag.categoryId == categoryId)
        #expect(tag.sortOrder == 2)
        #expect(tag.createdAt == now)
    }

    @Test
    func restoresArchivedTagWhenApplied() throws {
        let created = Date(timeIntervalSince1970: 1_790_000_000)
        let now = Date(timeIntervalSince1970: 1_791_000_000)

        let tag = EntryTag(
            categoryId: EntryCategory.ID(),
            name: "朝ごはん",
            sortOrder: 0,
            archivedAt: created,
            createdAt: created,
            updatedAt: created
        )

        var draft = EntryTagDraft(tag)
        draft.name = "モーニング"

        let updated = try draft.applied(to: tag, sortOrder: 3, at: now)

        #expect(updated.id == tag.id)
        #expect(updated.name == "モーニング")
        #expect(updated.sortOrder == 3)
        #expect(updated.archivedAt == nil)
        #expect(updated.createdAt == created)
        #expect(updated.updatedAt == now)
    }
}

extension EntryTagDraftTests {
    struct DraftCase: Decodable, Sendable {
        let name: String
        let problems: [EntryTagDraft.Problem]
    }
}

private extension EntryTagDraftTests {
    static var draftCases: [DraftCase] {
        get throws {
            try Fixture.load("category/entry-tag-draft.json")
        }
    }
}
