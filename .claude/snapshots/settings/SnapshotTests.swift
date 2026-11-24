import Core
@testable import DesignSystem
@testable import Features
import Store
import SwiftUI
import Testing
import UIKit

private let snapshotNow = Date(timeIntervalSince1970: 1_791_774_000)

@MainActor
struct SnapshotTests {
    @Test
    func render() async throws {
        let now = snapshotNow
        let today = LocalDate(now, in: .current)
        let database = try await Self.database(today: today, now: now)
        let options = try await database.entryOptions()
        let longWallet = options.wallets.max { $0.name.count < $1.name.count }
        let sheet = SettingsMenuSheet(
            database: database,
            clock: .fixed(snapshotNow),
            today: today,
            appIcon: AppIconListModel()
        )
        let wallets = SettingsBoardPage(WalletBoard(database: database))
        let rules = SettingsBoardPage(RewardRuleBoard(database: database))
        let categories = SettingsBoardPage(CategoryBoard(database: database, kind: .expense))
        let walletEdit = WalletEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            editing: longWallet?.id
        )

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
        await categories.model.load()
        await walletEdit.load()
        await reminder.load()
        await monthStart.load()
        await budgets.load()

        let walletSheet = WalletEditSheet(model: walletEdit)
            .frame(height: 1000)

        let categoryEdit = CategoryEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            kind: .expense
        )
        let stampEdit = StampEditModel(database: database, clock: .fixed(snapshotNow))
        let ruleEdit = RewardRuleEditModel(database: database, clock: .fixed(snapshotNow))

        await categoryEdit.load()
        await stampEdit.load()
        await ruleEdit.load()

        let editSheets: [(String, String, AnyView)] = [
            (
                "settings-category-edit",
                "設定 › カテゴリの編集",
                AnyView(CategoryEditSheet(model: categoryEdit))
            ),
            ("settings-stamp-edit", "設定 › スタンプの編集", AnyView(StampEditSheet(model: stampEdit))),
            (
                "settings-reward-edit",
                "設定 › ごほうびの決まりの編集",
                AnyView(RewardRuleEditSheet(model: ruleEdit))
            )
        ]

        for (name, title, view) in editSheets {
            for variant in Self.variants {
                try Self.write(view.frame(height: 1000), variant: variant, title: title, to: name)
            }
        }
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

        let recurring = RecurringListModel(
            database: database,
            clock: .fixed(snapshotNow),
            today: today
        )

        let observing = Task {
            await recurring.observe()
        }

        try await Self.wait {
            !recurring.output.rows.isEmpty
        }

        for type in Entry.Kind.allCases {
            recurring.state.type = type

            for variant in Self.variants {
                try Self.write(
                    RecurringListView(
                        board: RecurringBoard(
                            model: recurring,
                            database: database,
                            clock: .fixed(snapshotNow)
                        )
                    ),
                    variant: variant,
                    title: "設定 › 固定費 › \(Self.kindTitle(type))",
                    to: "settings-recurring-\(type.rawValue)"
                )
            }
        }

        observing.cancel()

        let templateEdit = TemplateEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            type: .expense
        )
        let recurringEdit = RecurringEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            today: today
        )

        await templateEdit.load()
        await recurringEdit.load()

        for variant in Self.variants {
            try Self.write(
                TemplateEditSheet(model: templateEdit).frame(height: 1000),
                variant: variant,
                title: "設定 › テンプレートの編集",
                to: "settings-template-edit"
            )
            try Self.write(
                RecurringEditSheet(model: recurringEdit).frame(height: 1000),
                variant: variant,
                title: "設定 › 固定費の編集",
                to: "settings-recurring-edit"
            )
        }

        let card = options.wallets.first { $0.kind == .card }
        let expenseEdit = RecurringEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            today: today
        )
        let transferEdit = RecurringEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            today: today,
            type: .transfer
        )

        await expenseEdit.load()
        await transferEdit.load()

        expenseEdit.state.schedule.day = 27
        transferEdit.state.toWalletId = card?.id

        for variant in Self.variants {
            try Self.write(
                RecurringQuickCard(model: expenseEdit) { _ in }.padding(20),
                variant: variant,
                title: "設定 › 固定費 › すぐ足す › 支出",
                to: "settings-recurring-quick-expense"
            )
            try Self.write(
                RecurringQuickCard(model: transferEdit) { _ in }.padding(20),
                variant: variant,
                title: "設定 › 固定費 › すぐ足す › 振替",
                to: "settings-recurring-quick-transfer"
            )
        }

        transferEdit.state.schedule.closingDay = 27

        for variant in Self.variants {
            try Self.write(
                RecurringQuickCard(model: transferEdit) { _ in }.padding(20),
                variant: variant,
                title: "設定 › 固定費 › すぐ足す › カードの引き落とし",
                to: "settings-recurring-quick-card-bill"
            )
        }

        let loanDraft = WalletDraft(
            kind: .loan,
            name: "日本学生支援機構 第二種（有利子）",
            mark: .glyph(.scholarship),
            color: "#4A6FA5",
            initialBalance: -3_896_752
        )

        let loan = try await database.save(loanDraft, at: snapshotNow)
        let loanEdit = RecurringEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            today: today,
            paying: loan.id
        )

        await loanEdit.load()

        for key in [AmountCalculator.Key.digit(1), .digit(6), .digit(2), .digit(3), .digit(5)] {
            loanEdit.state.press(key)
        }

        for variant in Self.variants {
            try Self.write(
                RecurringEditSheet(model: loanEdit).frame(height: 1900),
                variant: variant,
                title: "設定 › 固定費の編集 › 返済",
                to: "settings-recurring-loan"
            )
        }

        let savedTemplate = try await database.templates().first
        let templateEditing = TemplateEditModel(
            database: database,
            clock: .fixed(snapshotNow),
            type: .expense,
            editing: savedTemplate?.id
        )
        let budgetDrawer = BudgetListModel(database: database, today: today)
        let minusWallet = WalletEditModel(database: database, clock: .fixed(snapshotNow))

        await templateEditing.load()
        await budgetDrawer.load()

        budgetDrawer.startEditing(.total)
        minusWallet.state.name = "楽天カード"
        minusWallet.state.setKind(.card)

        for key in [AmountCalculator.Key.digit(5), .digit(2), .tripleZero] {
            minusWallet.state.press(key)
        }

        for variant in Self.variants {
            try Self.write(
                TemplateEditSheet(model: templateEditing).frame(height: 1000),
                variant: variant,
                title: "設定 › テンプレートの編集 › 保存済み",
                to: "settings-template-edit-editing"
            )
            try Self.write(
                BudgetListView(model: budgetDrawer).frame(height: 852),
                variant: variant,
                title: "設定 › 予算 › 提案",
                to: "settings-budgets-suggestions"
            )
            try Self.write(
                WalletEditSheet(model: minusWallet).frame(height: 1000),
                variant: variant,
                title: "設定 › 口座の編集 › マイナスの残高",
                to: "settings-wallet-edit-minus"
            )
        }

        templateEdit.state.setWallet(card?.id)
        recurringEdit.state.setWallet(card?.id)

        for variant in Self.variants {
            try Self.write(
                TemplateQuickCard(model: templateEdit) { _ in }.padding(20),
                variant: variant,
                title: "設定 › テンプレート › 引き落とし",
                to: "settings-template-bill"
            )
            try Self.write(
                RecurringQuickCard(model: recurringEdit) { _ in }.padding(20),
                variant: variant,
                title: "設定 › 固定費 › 引き落とし",
                to: "settings-recurring-bill"
            )
        }

        for variant in Self.variants {
            try Self.write(sheet, variant: variant, title: "設定 › メニュー", to: "settings")
            try Self.write(wallets, variant: variant, title: "設定 › 口座", to: "settings-wallets")
            try Self.write(rules, variant: variant, title: "設定 › ごほうびの決まり", to: "settings-rewards")
            try Self.write(
                categories,
                variant: variant,
                title: "設定 › カテゴリ",
                to: "settings-categories"
            )
            try Self.write(
                walletSheet,
                variant: variant,
                title: "設定 › 口座の編集",
                to: "settings-wallet-edit"
            )
            try Self.write(
                reminderView,
                variant: variant,
                title: "設定 › 通知",
                to: "settings-reminder"
            )
            try Self.write(
                monthStartView,
                variant: variant,
                title: "設定 › 月の始まり",
                to: "settings-month-start"
            )
            try Self.write(budgetView, variant: variant, title: "設定 › 予算", to: "settings-budgets")
            try Self.write(
                WidgetGuideView(database: database),
                variant: variant,
                title: "設定 › ウィジェットの案内",
                to: "settings-widget-guide"
            )
            try Self.write(
                WidgetGuideView(
                    database: database,
                    place: .home,
                    widget: .budget,
                    size: .small
                ),
                variant: variant,
                title: "設定 › ウィジェットの案内 › 小",
                to: "settings-widget-guide-small"
            )
            try Self.write(
                WidgetGuideView(
                    database: database,
                    place: .home,
                    widget: .quickRecord,
                    size: .large
                ),
                variant: variant,
                title: "設定 › ウィジェットの案内 › 大",
                to: "settings-widget-guide-large"
            )
            try Self.write(
                VStack(spacing: 16) {
                    WidgetGuideStage(place: .home, widget: .quickRecord, size: .medium)
                    WidgetGuideStage(place: .home, widget: .quickRecord, size: .large)
                }
                .padding(16),
                variant: variant,
                title: "設定 › ウィジェットの案内 › すばやく記録",
                to: "settings-widget-guide-quick"
            )
            try Self.write(
                WidgetGuideView(
                    database: database,
                    place: .lockScreen
                ),
                variant: variant,
                title: "設定 › ウィジェットの案内 › ロック画面",
                to: "settings-widget-guide-lock"
            )
            try Self.write(
                WidgetGuideView(
                    database: database,
                    place: .control
                ),
                variant: variant,
                title: "設定 › ウィジェットの案内 › コントロール",
                to: "settings-widget-guide-control"
            )
            try Self.write(
                ProView(model: ProPurchaseModel(store: .unavailable)),
                variant: variant,
                title: "設定 › Pro",
                to: "settings-pro"
            )
            try Self.write(
                WhatsNewSheet(seenVersion: nil, revealsSteps: false) { _ in },
                variant: variant,
                title: "お知らせ",
                to: "settings-whats-new"
            )
            try Self.write(
                WhatsNewSheet(seenVersion: "1.1.0", version: "1.1.0", revealsSteps: false) { _ in },
                variant: variant,
                title: "お知らせ › 前の版",
                to: "settings-whats-new-older"
            )
            try Self.write(
                intros,
                variant: variant,
                title: "設定 › 同期とバックアップの案内",
                to: "settings-intros"
            )
        }

        let choice = SyncChoiceCard(
            choice: SyncChoice(
                local: SyncSummary(entryCount: 1234, updatedAt: now),
                cloud: SyncSummary(entryCount: 1301, updatedAt: now.addingTimeInterval(3600))
            ),
            onUseLocal: {},
            onUseCloud: {},
            onKeep: {}
        )

        let shared = try SyncSharedCard(
            item: WalletShare(
                wallet: #require(options.wallets.first),
                icon: nil,
                isShared: true
            ),
            participants: [
                SyncParticipant(name: "山田 太郎", state: .owner),
                SyncParticipant(name: "山田 花子", state: .joined),
                SyncParticipant(name: "taro@example.com", state: .invited)
            ],
            isFailed: false,
            onInvite: {},
            onStop: {},
            onClose: {}
        )

        let squares: [(String, String, AnyView)] = [
            (
                "settings-pro-square",
                "設定 › Pro › 四角い角",
                AnyView(ProView(model: ProPurchaseModel(store: .unavailable)))
            ),
            (
                "settings-sync-choice-square",
                "設定 › 同期 › 選ぶ › 四角い角",
                AnyView(choice.frame(height: 852))
            ),
            (
                "settings-sync-shared-square",
                "設定 › 同期 › 共有中 › 四角い角",
                AnyView(shared.frame(height: 852))
            )
        ]

        for (name, title, view) in squares {
            for variant in Self.variants {
                try Self.write(
                    view.environment(\.themeStyle.corner, .square),
                    variant: variant,
                    title: title,
                    to: name
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

        var label: String {
            var parts = ["幅 \(Int(width))", scheme == .dark ? "ダーク" : "ライト"]

            switch textSize {
            case .standard: break
            case .small: parts.append("文字小")
            case .large: parts.append("文字大")
            }

            return parts.joined(separator: "・")
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular", width: 393, scheme: .light, textSize: .standard),
        Variant(name: "narrow", width: 320, scheme: .dark, textSize: .large),
        Variant(name: "pad", width: 704, scheme: .light, textSize: .standard)
    ]

    static func kindTitle(_ kind: Entry.Kind) -> String {
        switch kind {
        case .expense: "支出"
        case .income: "収入"
        case .transfer: "振替"
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

        let wallet = try await database.save(walletDraft, at: now)
        let category = try await database.saveCategory(categoryDraft, tags: [], at: now)
        let tagDraft = EntryTagDraft(name: "発表会の衣装と靴")
        let tags = try await database.saveTags([tagDraft], for: category.id, at: now)
        let rule = try await database.save(ruleDraft, at: now)
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
        title: String,
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

        try SnapshotIndex.record(
            directory: directory,
            file: "\(name)-\(variant.name).png",
            title: title,
            variant: variant.label
        )
    }
}
