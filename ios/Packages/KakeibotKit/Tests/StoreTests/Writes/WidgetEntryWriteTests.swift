import Core
import Foundation
import Store
import Testing

struct WidgetEntryWriteTests {
    @Test
    func recordsTemplateAndRemembersEntry() async throws {
        let setup = try await Setup()

        let template = try await setup.database.saveTemplate(
            setup.draft,
            at: setup.now
        )

        let entry = try await setup.database.recordFromWidget(
            template.id,
            on: setup.today,
            at: setup.now
        )

        let saved = try await setup.database.entry(entry.id)
        let remembered = try await setup.database.setting(.widgetEntry)

        #expect(saved?.amount == 980)
        #expect(saved?.date == setup.today)
        #expect(saved?.templateId == template.id)
        #expect(remembered == entry.id)
    }

    @Test
    func undoDeletesEntryAndForgetsIt() async throws {
        let setup = try await Setup()

        let template = try await setup.database.saveTemplate(
            setup.draft,
            at: setup.now
        )

        let entry = try await setup.database.recordFromWidget(
            template.id,
            on: setup.today,
            at: setup.now
        )

        try await setup.database.undoWidgetEntry(entry.id)
        let deleted = try await setup.database.entry(entry.id)
        let remembered = try await setup.database.setting(.widgetEntry)

        #expect(deleted == nil)
        #expect(remembered == nil)
    }

    @Test
    func rejectsTemplateWithoutAmount() async throws {
        let setup = try await Setup()
        var draft = setup.draft
        draft.amount = nil

        let template = try await setup.database.saveTemplate(draft, at: setup.now)

        await #expect(throws: AppDatabase.WidgetEntryError.amountMissing) {
            try await setup.database.recordFromWidget(
                template.id,
                on: setup.today,
                at: setup.now
            )
        }
    }
}

extension WidgetEntryWriteTests {
    struct Setup {
        let database: AppDatabase
        let now: Date
        let today: LocalDate
        let draft: EntryTemplateDraft
    }
}

extension WidgetEntryWriteTests.Setup {
    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = try #require(LocalDate(year: 2026, month: 10, day: 3))
        try database.insertDefaultsIfEmpty(at: now)
        let options = try await database.entryOptions()

        let draft = EntryTemplateDraft(
            name: "ランチ",
            type: .expense,
            amount: 980,
            categoryId: options.expenseCategories[0].id,
            walletId: options.wallets[0].id
        )

        self.init(database: database, now: now, today: today, draft: draft)
    }
}
