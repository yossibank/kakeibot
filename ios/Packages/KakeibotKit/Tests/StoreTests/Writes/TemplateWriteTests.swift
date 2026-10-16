import Core
import Foundation
import Store
import Testing

struct TemplateWriteTests {
    @Test
    func addsTemplatesInOrder() async throws {
        let setup = try await Setup()

        let lunch = try await setup.database.saveTemplate(
            setup.draft,
            at: setup.now
        )
        var coffee = setup.draft
        coffee.name = "コーヒー"
        let saved = try await setup.database.saveTemplate(coffee, at: setup.now)
        let templates = try await setup.database.templates()

        #expect(lunch.sortOrder == 0)
        #expect(saved.sortOrder == 1)
        #expect(templates.map(\.name) == ["ランチ", "コーヒー"])
    }

    @Test
    func updatesAndDeletesTemplate() async throws {
        let setup = try await Setup()
        let later = setup.now.addingTimeInterval(60)
        var edited = setup.draft
        edited.amount = nil

        let saved = try await setup.database.saveTemplate(
            setup.draft,
            at: setup.now
        )
        let updated = try await setup.database.saveTemplate(
            edited,
            editing: saved.id,
            at: later
        )
        let afterUpdate = try await setup.database.templates()

        try await setup.database.deleteTemplate(saved.id)
        let afterDelete = try await setup.database.templates()

        #expect(updated.id == saved.id)
        #expect(afterUpdate.first?.amount == nil)
        #expect(afterDelete.isEmpty)
    }

    @Test
    func reordersTemplates() async throws {
        let setup = try await Setup()
        var names: [String] = []

        for name in ["ランチ", "コーヒー", "定期"] {
            var draft = setup.draft
            draft.name = name
            try await setup.database.saveTemplate(draft, at: setup.now)
            names.append(name)
        }

        let ids = try await setup.database.templates().map(\.id)
        try await setup.database.reorderTemplates(
            ids.reversed(),
            at: setup.now
        )
        let reordered = try await setup.database.templates()

        #expect(reordered.map(\.name) == names.reversed())
    }

    @Test
    func clearsTemplateOfEntriesWhenDeleted() async throws {
        let setup = try await Setup()

        let template = try await setup.database.saveTemplate(
            setup.draft,
            at: setup.now
        )
        let today = try #require(LocalDate(year: 2026, month: 10, day: 3))
        let draft = try #require(template.entryDraft(on: today))
        let entry = try await setup.database.saveEntry(draft, at: setup.now)

        try await setup.database.deleteTemplate(template.id)
        let kept = try await setup.database.entry(entry.id)
        try await setup.database.deleteEntry(entry.id)
        try await setup.database.restoreEntry(entry)
        let restored = try await setup.database.entry(entry.id)

        #expect(entry.templateId == template.id)
        #expect(kept?.amount == 980)
        #expect(kept?.templateId == nil)
        #expect(restored?.templateId == nil)
    }

    @Test
    func rejectsUnknownTemplate() async throws {
        let setup = try await Setup()

        await #expect(throws: AppDatabase.TemplateWriteError.templateNotFound) {
            try await setup.database.saveTemplate(
                setup.draft,
                editing: EntryTemplate.ID(),
                at: setup.now
            )
        }
    }
}

extension TemplateWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let draft: EntryTemplateDraft
    }
}

extension TemplateWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()

        let draft = EntryTemplateDraft(
            name: "ランチ",
            type: .expense,
            amount: 980,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )

        self.init(database: database, now: now, draft: draft)
    }
}
