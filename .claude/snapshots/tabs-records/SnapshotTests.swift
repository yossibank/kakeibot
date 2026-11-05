import Core
@testable import DesignSystem
@testable import Features
import Store
import SwiftUI
import Testing
import UIKit

@MainActor
struct SnapshotTests {
    @Test
    func render() async throws {
        let now = Date()
        let today = LocalDate(now, in: .current)
        let database = try await Self.database(today: today, now: now)
        let model = RecordsModel(database: database, today: today)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.list != nil && !model.recurrings.isEmpty
        }

        for layout in [RecordsLayout.calendar, .list] {
            model.setLayout(layout)
            model.selectedDate = today

            for variant in Self.variants {
                let view = RecordsView(
                    model: model,
                    onOpenEntry: { _ in },
                    onAddEntry: { _ in },
                    onOpenRecurring: { _ in },
                    onChangeEntries: { _, _ in },
                    onDeleteEntries: { _ in }
                )

                try Self.write(view, variant: variant, to: "records-\(layout.rawValue)")
            }
        }

        model.setLayout(.list)

        let selectedDays = model.days.prefix(2)
        let firstDayIds = selectedDays.first?.entries.map(\.id) ?? []
        let secondDayIds = selectedDays.dropFirst().first?.entries.prefix(1).map(\.id) ?? []
        let selection = Set(firstDayIds + secondDayIds)

        for variant in Self.variants {
            let view = RecordsView(
                model: model,
                selection: selection,
                onOpenEntry: { _ in },
                onAddEntry: { _ in },
                onOpenRecurring: { _ in },
                onChangeEntries: { _, _ in },
                onDeleteEntries: { _ in }
            )

            try Self.write(view, variant: variant, to: "records-selecting")
        }

        let deletions = Self.deletions(in: model)

        for (name, change) in deletions {
            for variant in Self.variants {
                let notice = EntryNoticeModel(database: database)
                notice.show(change)

                let view = Color.clear
                    .frame(height: 140)
                    .entryNotice(notice, above: 0)

                try Self.write(view, variant: variant, to: "records-deleted-\(name)")
            }
        }

        model.move(months: -1)

        try await Self.wait {
            !model.isCurrentMonth
        }

        for variant in Self.variants {
            let view = RecordsView(
                model: model,
                onOpenEntry: { _ in },
                onAddEntry: { _ in },
                onOpenRecurring: { _ in },
                onChangeEntries: { _, _ in },
                onDeleteEntries: { _ in }
            )

            try Self.write(view, variant: variant, to: "records-previous-month")
        }

        try await Self.writeSearchAndFilter(model, database: database)

        task.cancel()

        let entryId = Entry.ID()

        let items = [
            ("牛乳", 2, 396, EntryItem.TaxRate?.some(.reduced)),
            ("食パン", 1, 250, .reduced),
            ("洗剤", 1, 398, .standard),
            ("弁当", 1, 540, nil),
            ("国産大豆の絹ごし豆腐3個パック", 12, 1188, .reduced)
        ]
        .enumerated()
        .map { index, item in
            EntryItem(
                entryId: entryId,
                name: item.0,
                quantity: item.1,
                amount: item.2,
                taxRate: item.3,
                sortOrder: index,
                createdAt: now,
                updatedAt: now
            )
        }

        for theme in [ThemePreset.white, .black, .rose] {
            for variant in Self.variants {
                let receipt = RecordsItemReceipt(items: items, amount: 1674)
                    .padding(24)
                    .background(Palette.background)
                    .environment(\.palette, theme.palette)

                try Self.write(
                    receipt,
                    variant: variant,
                    to: "records-item-receipt-\(theme.rawValue)"
                )

                let adjusted = RecordsItemReceipt(items: items, amount: 1600)
                    .padding(24)
                    .background(Palette.background)
                    .environment(\.palette, theme.palette)

                try Self.write(
                    adjusted,
                    variant: variant,
                    to: "records-item-adjusted-\(theme.rawValue)"
                )

                let included = RecordsItemReceipt(
                    taxIncluded: true,
                    items: Self.includedItems(entryId: entryId, now: now),
                    amount: 3170
                )
                .padding(24)
                .background(Palette.background)
                .environment(\.palette, theme.palette)

                try Self.write(
                    included,
                    variant: variant,
                    to: "records-item-included-\(theme.rawValue)"
                )
            }
        }
    }
}

extension SnapshotTests {
    struct Variant {
        let name: String
        let width: CGFloat
        let scheme: ColorScheme
        let textSize: ThemeTextSize
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular", width: 393, scheme: .light, textSize: .standard),
        Variant(name: "narrow", width: 320, scheme: .dark, textSize: .large)
    ]

    static func includedItems(
        entryId: Entry.ID,
        now: Date
    ) -> [EntryItem] {
        [("T/O オムレツサンド", 780), ("絹香食パン", 890), ("スイートポテト", 1500)]
            .enumerated()
            .map { index, item in
                EntryItem(
                    entryId: entryId,
                    name: item.0,
                    quantity: 1,
                    amount: item.1,
                    taxRate: .reduced,
                    sortOrder: index,
                    createdAt: now,
                    updatedAt: now
                )
            }
    }

    static func writeSearchAndFilter(
        _ model: RecordsModel,
        database: AppDatabase
    ) async throws {
        let options = try await database.entryOptions()
        let income = try #require(options.incomeCategories.last)

        model.isSearching = true
        model.searchText = "サブスクの解約金"

        for variant in variants {
            try write(recordsView(model), variant: variant, to: "records-search-empty")
        }

        model.searchText = "発表会"

        let category = try #require(model.searchDays.first?.entries.first?.categoryId)

        model.filter = EntryFilter(categoryIds: [income.id])

        for variant in variants {
            try write(recordsView(model), variant: variant, to: "records-search-filtered")
        }

        model.filter = EntryFilter(categoryIds: [category])
        model.openCurrentMonth()

        for variant in variants {
            let sheet = RecordsFilterSheet(model: model)
                .frame(height: 720)

            try write(sheet, variant: variant, to: "records-filter-sheet")
        }

        model.filter = EntryFilter(categoryIds: [income.id])

        for variant in variants {
            let sheet = RecordsFilterSheet(model: model)
                .frame(height: 720)

            try write(sheet, variant: variant, to: "records-filter-sheet-none")
        }

        model.clearFilter()
    }

    static func recordsView(_ model: RecordsModel) -> RecordsView {
        RecordsView(
            model: model,
            onOpenEntry: { _ in },
            onAddEntry: { _ in },
            onOpenRecurring: { _ in },
            onChangeEntries: { _, _ in },
            onDeleteEntries: { _ in }
        )
    }

    static func deletions(in model: RecordsModel) -> [(String, EntryChange)] {
        guard let list = model.list else {
            return []
        }

        let entries = model.days.flatMap(\.entries)

        let label = { (entry: Entry) in
            EntryChange.label(for: entry) { id in
                list.categories[id]
            } wallet: { id in
                list.wallets[id]
            }
        }

        let long = entries.first { entry in
            !(entry.memo ?? "").isEmpty
        }

        let unnamed = entries.last { entry in
            (entry.memo ?? "").isEmpty
        }

        var short = long
        short?.memo = "ランチ"
        short?.amount = 900

        return [("long", long), ("short", short), ("category", unnamed)]
            .compactMap { name, entry in
                entry.map { entry in
                    (name, EntryChange(kind: .deleted, entry: entry, label: label(entry)))
                }
            }
    }

    static func wait(until isReady: () -> Bool) async throws {
        for _ in 0..<300 where !isReady() {
            try await Task.sleep(for: .milliseconds(10))
        }

        try await Task.sleep(for: .milliseconds(300))
    }

    static func database(
        today: LocalDate,
        now: Date
    ) async throws -> AppDatabase {
        let database = try AppDatabase.inMemory()

        try database.insertDefaultsIfEmpty(at: now)
        try await SettingsMenuSampleData.insert(into: database, today: today, now: now)

        let walletDraft = WalletDraft(
            kind: .bank,
            name: "みずほ銀行 普通預金 給与と生活費の口座",
            mark: .glyph(.bank),
            color: "#4A6FA5",
            initialBalance: 98_765_432
        )

        let categoryDraft = EntryCategoryDraft(
            kind: .expense,
            name: "子どもの習い事と教材と遠征費",
            mark: .glyph(.hobby),
            color: "#E07A5F"
        )

        let ruleDraft = RewardRuleDraft(
            name: "コンビニに寄らずにまっすぐ家に帰れた日",
            amount: 12345,
            icon: IconDraft(mark: .glyph(.food), color: "#E8735A")
        )

        let goalDraft = RewardGoalDraft(
            name: "ずっと欲しかった電動アシスト自転車",
            targetAmount: 1_234_567
        )

        let wallet = try await database.saveWallet(walletDraft, at: now)
        let category = try await database.saveCategory(categoryDraft, tags: [], at: now)
        let tagDraft = EntryTagDraft(name: "発表会の衣装と靴")
        let tags = try await database.saveTags([tagDraft], for: category.id, at: now)
        let rule = try await database.saveRewardRule(ruleDraft, at: now)
        let options = try await database.entryOptions()

        _ = try await database.saveRewardGoal(goalDraft, at: now)

        let templateDraft = EntryTemplateDraft(
            name: "子どもの習い事の月謝まとめ払い",
            type: .expense,
            amount: 1_234_567,
            categoryId: category.id,
            tagId: tags.first?.id,
            walletId: wallet.id
        )

        _ = try await database.saveTemplate(templateDraft, at: now)

        let drafts = [
            EntryDraft(
                type: .expense,
                amount: 1_234_567,
                date: today,
                categoryId: category.id,
                tagId: tags.first?.id,
                walletId: wallet.id,
                memo: "発表会の衣装と靴と髪飾りをまとめて買った",
                items: [
                    EntryItem.Draft(name: "発表会の衣装", amount: 1_000_000),
                    EntryItem.Draft(name: "靴", quantity: 2, amount: 200_000, taxRate: .standard),
                    EntryItem.Draft(name: "髪飾り", amount: 34567)
                ]
            ),
            EntryDraft(
                type: .income,
                amount: 12_345_678,
                date: today,
                categoryId: options.incomeCategories.first?.id,
                walletId: wallet.id
            ),
            EntryDraft(
                type: .expense,
                amount: 9_876_543,
                date: today.adding(days: -1),
                categoryId: category.id,
                walletId: wallet.id
            )
        ]

        try await database.saveEntries(drafts, at: now)
        try await database.setReward(rule.id, isAchieved: true, on: today, at: now)

        return database
    }

    static func write(
        _ view: some View,
        variant: Variant,
        to name: String
    ) throws {
        let style = ThemeStyle(
            corner: .standard,
            displayFont: .mincho,
            textFont: .gothic,
            textSize: variant.textSize
        )

        let content = view
            .frame(width: variant.width)
            .frame(maxHeight: maxHeight, alignment: .top)
            .clipped()
            .background(Palette.background)
            .environment(\.themeStyle, style)
            .environment(\.colorScheme, variant.scheme)

        let renderer = ImageRenderer(content: content)

        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: variant.width, height: nil)

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: "\(name)-\(variant.name).png")

        try data.write(to: url)
    }
}
