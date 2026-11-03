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

        for state in Self.states {
            for variant in Self.variants {
                let model = ThemeStyleModel(database: database)
                let style = state.style(textSize: variant.textSize)

                await model.choose(style.corner)
                await model.choose(style.textSize)
                await model.choose(style.rowSpacing)
                await model.choose(style.stampShape)
                await model.choose(showsTabTitles: style.showsTabTitles)
                await model.choose(style.backdrop)
                await model.choose(haptics: style.haptics)
                await model.choose(decorations: style.decorations)
                await model.load()

                let sheet = SettingsMenuSheet(
                    database: database,
                    today: today,
                    appIcon: AppIconListModel()
                )

                try Self.write(
                    ThemeStyleLookView(model: model),
                    style: style,
                    variant: variant,
                    to: "look-\(state.name)"
                )
                try Self.write(sheet, style: style, variant: variant, to: "settings-\(state.name)")

                if state.name == "standard" {
                    try Self.write(
                        ThemeStyleTextView(model: model),
                        style: style,
                        variant: variant,
                        to: "text"
                    )
                }
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

    struct State {
        let name: String
        let corner: ThemeCorner
        let rowSpacing: ThemeRowSpacing
        let stampShape: ThemeStampShape
        let showsTabTitles: Bool
        let backdrop: ThemeBackdrop
        let isOn: Bool

        func style(textSize: ThemeTextSize) -> ThemeStyle {
            ThemeStyle(
                corner: corner,
                displayFont: .mincho,
                textFont: .gothic,
                textSize: textSize,
                rowSpacing: rowSpacing,
                stampShape: stampShape,
                showsTabTitles: showsTabTitles,
                backdrop: backdrop,
                haptics: isOn,
                decorations: isOn
            )
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular-light", width: 393, scheme: .light, textSize: .standard),
        Variant(name: "regular-dark", width: 393, scheme: .dark, textSize: .standard),
        Variant(name: "narrow-light", width: 320, scheme: .light, textSize: .large),
        Variant(name: "narrow-dark", width: 320, scheme: .dark, textSize: .large)
    ]

    static let states = [
        State(
            name: "standard",
            corner: .standard,
            rowSpacing: .standard,
            stampShape: .circle,
            showsTabTitles: true,
            backdrop: .plain,
            isOn: true
        ),
        State(
            name: "ruled",
            corner: .square,
            rowSpacing: .compact,
            stampShape: .seal,
            showsTabTitles: false,
            backdrop: .ruled,
            isOn: false
        ),
        State(
            name: "grid",
            corner: .large,
            rowSpacing: .relaxed,
            stampShape: .rounded,
            showsTabTitles: true,
            backdrop: .grid,
            isOn: true
        )
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
        style: ThemeStyle,
        variant: Variant,
        to name: String
    ) throws {
        let palette = ThemeLook.followsDevice.palette(isDark: variant.scheme == .dark)

        let content = view
            .frame(width: variant.width)
            .frame(maxHeight: maxHeight, alignment: .top)
            .clipped()
            .background(Palette.background)
            .environment(\.themeStyle, style)
            .environment(\.palette, palette)
            .environment(\.colorScheme, variant.scheme)

        let renderer = ImageRenderer(content: content)

        renderer.scale = 2
        renderer.proposedSize = ProposedViewSize(width: variant.width, height: nil)

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: "\(name)-\(variant.name).png")

        try data.write(to: url)
    }
}
