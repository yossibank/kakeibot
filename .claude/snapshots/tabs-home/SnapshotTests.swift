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
        let model = HomeModel(database: database, today: today)
        let setup = SetupModel(database: database)
        let appIcon = AppIconListModel()

        let tasks = [
            Task {
                await model.run()
            },
            Task {
                await setup.run()
            }
        ]

        try await Self.wait {
            model.list != nil && !model.templates.isEmpty
        }

        for variant in Self.variants {
            let view = HomeView(
                model: model,
                setup: setup,
                appIcon: appIcon,
                isSheetOpen: false,
                onOpenEntry: { _ in },
                onShowRecords: {},
                onAddEntry: { _ in },
                onRetry: {},
                onOpenSettings: {},
                onOpenNews: {},
                onUseTemplate: { _ in },
                onShowAllTemplates: {},
                onOpenOrderMenu: { _ in },
                onAddTemplate: {},
                onDeleteEntry: { _ in },
                onOpenRecurrings: {},
                onOpenRecurring: { _ in },
                onOpenSetup: { _ in },
                onOpenDay: { _ in }
            )

            let sheet = HomeRecurringSheet(model: model) { _ in }

            try Self.write(view, variant: variant, to: "home")
            try Self.write(view.billCard.padding(16), variant: variant, to: "home-bills")

            model.billPage = 1

            try Self.write(view.billCard.padding(16), variant: variant, to: "home-bills-next")

            model.billPage = 0
            try Self.write(sheet, variant: variant, to: "home-recurring")
        }

        for task in tasks {
            task.cancel()
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
                memo: "発表会の衣装と靴と髪飾りをまとめて買った"
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
        try await insertSecondCard(into: database, today: today, now: now)

        return database
    }

    static func insertSecondCard(
        into database: AppDatabase,
        today: LocalDate,
        now: Date
    ) async throws {
        let options = try await database.entryOptions()
        let bank = try #require(options.wallets.first { $0.kind == .bank })
        let category = options.expenseCategories.first?.id

        let cardDraft = WalletDraft(
            kind: .card,
            name: "楽天カード",
            mark: .glyph(.card),
            color: "#C0392B",
            initialBalance: 0
        )

        let card = try await database.saveWallet(cardDraft, at: now)
        let lastMonth = today.yearMonth.adding(months: -1)
        let start = try #require(LocalDate(yearMonth: lastMonth, day: 1))

        let drafts = try [
            (#require(LocalDate(yearMonth: lastMonth, day: 5)), 28400),
            (#require(LocalDate(yearMonth: lastMonth, day: 18)), 19800),
            (#require(LocalDate(yearMonth: today.yearMonth, day: 1)), 12400)
        ].map { date, amount in
            EntryDraft(
                type: .expense,
                amount: amount,
                date: min(date, today),
                categoryId: category,
                walletId: card.id
            )
        }

        let recurring = RecurringDraft(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank.id,
            toWalletId: card.id,
            memo: "楽天カード",
            frequency: .monthly,
            month: today.month,
            day: 27,
            closingDay: 31,
            startDate: start
        )

        try await database.saveEntries(drafts, at: now)
        try await database.saveRecurring(recurring, today: today, at: now)
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
