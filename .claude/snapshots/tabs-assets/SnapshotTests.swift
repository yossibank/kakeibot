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
        let model = AssetsModel(database: database, today: today)
        let task = Task {
            await model.run()
        }

        try await Self.wait {
            model.list != nil && model.rewardBank != nil
        }

        for variant in Self.variants {
            let view = AssetsView(
                model: model,
                onTransfer: {},
                onOpenWallet: { _ in },
                onOpenRecurring: { _ in },
                onOpenEntry: { _ in },
                onMarkReward: {}
            )

            try Self.write(view, variant: variant, to: "assets")

            let reward = AssetsRewardSheet(model: model)
                .frame(height: 1400)

            try Self.write(reward, variant: variant, to: "assets-reward")

            let adding = AssetsGoalSheet(model: model.goalEditModel(editing: nil))
                .frame(height: 852)

            try Self.write(adding, variant: variant, to: "assets-goal-new")

            let goal = try #require(model.waitingGoals.first)

            let editing = AssetsGoalSheet(model: model.goalEditModel(editing: goal))
                .frame(height: 852)

            try Self.write(editing, variant: variant, to: "assets-goal-edit")

            let card = try #require(model.rows.first { $0.unpaid != nil })
            let unpaid = try #require(card.unpaid)
            let bill = try #require(card.nextBill)
            let content = AssetsEntrySheet.Content.unpaid(unpaid, of: card, bill: bill)

            let unpaidSheet = AssetsEntrySheet(content: content) { _ in }
                .frame(height: 1200)

            try Self.write(unpaidSheet, variant: variant, to: "assets-unpaid")

            let plans = AssetsPlanSheet(model: model) { _ in }.content
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .background(Palette.panel)

            try Self.write(plans, variant: variant, to: "assets-plans")

            let wallet = try #require(model.rows.first)

            for (name, keys) in [
                ("assets-adjust", [AmountCalculator.Key]()),
                ("assets-adjust-typed", [.digit(4), .digit(8), .digit(2), .doubleZero])
            ] {
                let adjust = model.adjustModel(for: wallet)

                for key in keys {
                    adjust.press(key)
                }

                let sheet = AssetsAdjustSheet(model: adjust).content
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .background(Palette.panel)

                try Self.write(sheet, variant: variant, to: name)
            }
        }

        task.cancel()

        let emptyModel = try AssetsModel(database: AppDatabase.inMemory(), today: today)
        let emptyTask = Task {
            await emptyModel.run()
        }

        try await Self.wait {
            emptyModel.list != nil
        }

        for variant in Self.variants {
            let view = AssetsView(
                model: emptyModel,
                onTransfer: {},
                onOpenWallet: { _ in },
                onOpenRecurring: { _ in },
                onOpenEntry: { _ in },
                onMarkReward: {}
            )

            try Self.write(view, variant: variant, to: "assets-empty")
        }

        emptyTask.cancel()
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
        Variant(name: "narrow", width: 320, scheme: .dark, textSize: .large),
        Variant(name: "wide", width: 609, scheme: .light, textSize: .standard)
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
            ),
            EntryDraft(
                type: .expense,
                amount: 4000,
                date: today.adding(days: 7),
                categoryId: category.id,
                walletId: wallet.id
            ),
            EntryDraft(
                type: .income,
                amount: 250_000,
                date: today.adding(days: 14),
                categoryId: options.incomeCategories.first?.id,
                walletId: wallet.id
            ),
            EntryDraft(
                type: .expense,
                amount: 12500,
                date: today.adding(days: 21),
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
