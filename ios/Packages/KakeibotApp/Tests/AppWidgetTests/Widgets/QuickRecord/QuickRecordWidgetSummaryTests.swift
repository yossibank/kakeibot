@testable import AppWidget
import Core
import Foundation
import Store
import Testing

struct QuickRecordWidgetSummaryTests {
    @Test
    func showsOnlyExpenseTemplatesUpToSix() async throws {
        let setup = try await Setup()

        for index in 1...7 {
            try await setup.saveTemplate("支出\(index)", type: .expense)
        }

        try await setup.saveTemplate("給料", type: .income)

        let summary = try await setup.summary()

        #expect(summary.tiles.map(\.name) == (1...6).map { "支出\($0)" })
    }

    @Test
    func showsTwoRecordsOfTodayAndCountsAll() async throws {
        let setup = try await Setup()

        for amount in [100, 200, 300] {
            _ = try await setup.saveEntry(amount: amount)
        }

        let summary = try await setup.summary()

        #expect(summary.todayRecords.count == 2)
        #expect(summary.todayCount == 3)
        #expect(summary.todayExpense == 600)
    }

    @Test
    func offersUndoForFiveSeconds() async throws {
        let setup = try await Setup()
        let entry = try await setup.saveEntry(amount: 980)

        let summary = try await setup.summary(recordedId: entry.id)
        let justBefore = summary.recorded(at: setup.now.addingTimeInterval(4.9))
        let atLimit = summary.recorded(at: setup.now.addingTimeInterval(5))

        #expect(justBefore?.id == entry.id)
        #expect(justBefore?.amount == 980)
        #expect(atLimit == nil)
        #expect(summary.clearingRecorded().recorded == nil)
    }

    @Test
    func namesUndoAfterTemplateOrCategory() async throws {
        let setup = try await Setup()
        let template = try await setup.saveTemplate("ランチ", type: .expense)
        let withTemplate = try await setup.saveEntry(amount: 980, templateId: template.id)
        let named = try await setup.summary(recordedId: withTemplate.id)

        _ = try await setup.database.deleteTemplate(template.id)
        let afterDeletion = try await setup.summary(recordedId: withTemplate.id)

        #expect(named.recorded?.name == "ランチ")
        #expect(afterDeletion.recorded?.name == setup.categoryName)
    }

    @Test
    func showsNothingWithoutRecords() async throws {
        let setup = try await Setup()

        let summary = try await setup.summary(recordedId: Entry.ID())

        #expect(summary.todayExpense == 0)
        #expect(summary.todayRecords.isEmpty)
        #expect(summary.todayCount == 0)
        #expect(summary.recorded == nil)
    }
}

extension QuickRecordWidgetSummaryTests {
    struct Setup {
        let database: AppDatabase
        let today: LocalDate
        let now: Date
        let options: EntryOptions
    }
}

extension QuickRecordWidgetSummaryTests.Setup {
    var categoryName: String? {
        options.expenseCategories.first?.name
    }

    init() async throws {
        let database = try AppDatabase.inMemory()
        let now = Date(timeIntervalSince1970: 1_791_000_000)
        let today = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let options = try await database.entryOptions()

        self.init(
            database: database,
            today: today,
            now: now,
            options: options
        )
    }

    @discardableResult
    func saveTemplate(
        _ name: String,
        type: Entry.Kind
    ) async throws -> EntryTemplate {
        let categories = type == .income ? options.incomeCategories : options.expenseCategories

        let draft = EntryTemplateDraft(
            name: name,
            type: type,
            amount: 500,
            categoryId: categories.first?.id,
            walletId: options.wallets.first?.id
        )

        return try await database.saveTemplate(draft, at: now)
    }

    func saveEntry(
        amount: Int,
        templateId: EntryTemplate.ID? = nil
    ) async throws -> Entry {
        let draft = EntryDraft(
            type: .expense,
            amount: amount,
            date: today,
            categoryId: options.expenseCategories.first?.id,
            templateId: templateId,
            walletId: options.wallets[0].id
        )

        return try await database.saveEntryResult(draft, at: now).entry
    }

    func summary(recordedId: Entry.ID? = nil) async throws -> QuickRecordWidgetSummary {
        let overview = try await database.widgetOverview(on: today, including: recordedId)
        let templates = try await database.templates()

        return QuickRecordWidgetSummary(
            overview,
            templates: templates,
            order: .manual,
            recordedId: recordedId
        )
    }
}
