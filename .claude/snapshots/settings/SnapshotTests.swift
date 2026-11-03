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
        let options = try await database.entryOptions()
        let longWallet = options.wallets.max { $0.name.count < $1.name.count }
        let sheet = SettingsMenuSheet(database: database, today: today, appIcon: AppIconListModel())
        let wallets = WalletListView(database: database)
        let rules = RewardRuleListView(database: database)
        let walletEdit = WalletEditModel(database: database, editing: longWallet?.id)

        let reminder = ReminderModel(
            database: database,
            today: today,
            time: .evening,
            permission: .allowed
        )

        let monthStart = MonthStartDayModel(database: database, today: today)
        let budgets = BudgetListModel(database: database, today: today)
        let payday = try #require(MonthStartDay(25, shift: .previous))
        let carryoverFrom = today.yearMonth.adding(months: -2)

        try await database.setSetting(.monthStartDay, to: payday)
        try await database.setSetting(.budgetCarryoverFrom, to: carryoverFrom)

        await wallets.model.load()
        await rules.model.load()
        await walletEdit.load()
        await reminder.load()
        await monthStart.load()
        await budgets.load()

        let walletSheet = WalletEditSheet(model: walletEdit)
        let reminderView = ReminderView(model: reminder)
        let monthStartView = MonthStartDayView(model: monthStart)
        let budgetView = BudgetListView(model: budgets)
        let exportedAt = now.addingTimeInterval(-40 * 24 * 60 * 60)

        let intros = VStack(spacing: 16) {
            SyncIntroCard()

            BackupIntroCard()
        }
        .padding(20)

        try await database.setSetting(.backupExportedAt, to: exportedAt)

        for variant in Self.variants {
            try Self.write(sheet, variant: variant, to: "settings")
            try Self.write(wallets, variant: variant, to: "settings-wallets")
            try Self.write(rules, variant: variant, to: "settings-rewards")
            try Self.write(walletSheet, variant: variant, to: "settings-wallet-edit")
            try Self.write(reminderView, variant: variant, to: "settings-reminder")
            try Self.write(monthStartView, variant: variant, to: "settings-month-start")
            try Self.write(budgetView, variant: variant, to: "settings-budgets")
            try Self.write(WidgetGuideView(), variant: variant, to: "settings-widget-guide")
            try Self.write(
                WidgetGuideView(place: .home, widget: .budget, size: .small),
                variant: variant,
                to: "settings-widget-guide-small"
            )
            try Self.write(
                WidgetGuideView(place: .home, widget: .quickRecord, size: .large),
                variant: variant,
                to: "settings-widget-guide-large"
            )
            try Self.write(
                WidgetGuideView(place: .lockScreen),
                variant: variant,
                to: "settings-widget-guide-lock"
            )
            try Self.write(
                WidgetGuideView(place: .control),
                variant: variant,
                to: "settings-widget-guide-control"
            )
            try Self.write(
                ProView(model: ProPurchaseModel(store: .unavailable)),
                variant: variant,
                to: "settings-pro"
            )
            try Self.write(
                WhatsNewSheet(seenVersion: nil, revealsSteps: false) { _ in },
                variant: variant,
                to: "settings-whats-new"
            )
            try Self.write(intros, variant: variant, to: "settings-intros")
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
