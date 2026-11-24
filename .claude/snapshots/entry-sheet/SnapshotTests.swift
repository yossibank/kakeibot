import Core
@testable import DesignSystem
@testable import FeatureModels
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
        for (name, title, type, digits, deck) in Self.cases {
            let model = try await Self.model(type, digits: digits)

            let view = EntrySheet(model: model, deck: deck)
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Color(uiColor: .systemBackground))
                .environment(\.colorScheme, .light)

            try Self.write(
                view,
                title: "記録の入力 › \(title)",
                variant: Self.label(Self.phone),
                to: "\(name).png"
            )

            let dark = EntrySheet(model: model, deck: deck)
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Palette.background)
                .environment(\.canScanReceipt, true)
                .environment(\.palette, ThemePreset.black.palette)

            try Self.write(
                dark,
                title: "記録の入力 › \(title)",
                variant: Self.label(Self.phone, isDark: true),
                to: "\(name)-dark.png"
            )
        }

        let startModel = try await Self.startModel()

        let start = EntrySheet(model: startModel, deck: .category)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Palette.background)
            .environment(\.canScanReceipt, true)

        try Self.write(
            start,
            title: "記録の入力 › 開いた直後",
            variant: Self.label(Self.phone),
            to: "entry-start.png"
        )

        let startDark = EntrySheet(model: startModel, deck: .category)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Palette.background)
            .environment(\.canScanReceipt, true)
            .environment(\.palette, ThemePreset.black.palette)

        try Self.write(
            startDark,
            title: "記録の入力 › 開いた直後",
            variant: Self.label(Self.phone, isDark: true),
            to: "entry-start-dark.png"
        )

        let model = try await Self.model(.expense, digits: Self.smallDigits)
        let style = ThemeStyle(
            corner: .standard,
            displayFont: .mincho,
            textFont: .gothic,
            textSize: .large
        )
        let mini = EntrySheet(model: model)
            .frame(width: Self.mini.width, height: Self.mini.height)
            .background(Palette.background)
            .environment(\.themeStyle, style)
            .environment(\.colorScheme, .dark)

        try Self.write(
            mini,
            title: "記録の入力 › 支出の金額",
            variant: Self.label(Self.mini, isDark: true, isLarge: true),
            to: "entry-mini-large.png"
        )

        let tallCases: [(String, String, CGSize, EntryDeck)] = [
            ("entry-tall-expense", "支出の金額", Self.tall, .amount),
            ("entry-tall-date", "日付の選択", Self.tall, .date),
            ("entry-mini-date", "日付の選択", Self.mini, .date),
            ("entry-max-expense", "支出の金額", Self.max, .amount),
            ("entry-pad-form-expense", "支出の金額", Self.padForm, .amount),
            ("entry-pad-form-date", "日付の選択", Self.padForm, .date),
            ("entry-pad-page-expense", "支出の金額", Self.padPage, .amount),
            ("entry-pad-page-date", "日付の選択", Self.padPage, .date),
            ("entry-pad-tall-expense", "支出の金額", Self.padTall, .amount),
            ("entry-short-expense", "支出の金額", Self.short, .amount),
            ("entry-short-date", "日付の選択", Self.short, .date)
        ]

        for (name, title, size, deck) in tallCases {
            let tallModel = try await Self.model(.expense, digits: Self.smallDigits)

            let tallView = EntrySheet(model: tallModel, deck: deck)
                .frame(width: size.width, height: size.height)
                .background(Color(uiColor: .systemBackground))
                .environment(\.colorScheme, .light)

            try Self.write(
                tallView,
                title: "記録の入力 › \(title)",
                variant: Self.label(size),
                to: "\(name).png"
            )
        }

        let closedModel = try await Self.model(
            .expense,
            digits: Self.smallDigits
        )

        for (name, size) in [("entry-editing", Self.phone), ("entry-editing-narrow", Self.narrow)] {
            let editing = try await Self.editingModel()

            let edit = EntrySheet(model: editing)
                .frame(width: size.width, height: size.height)
                .background(Color(uiColor: .systemBackground))
                .environment(\.colorScheme, .light)

            try Self.write(
                edit,
                title: "記録の入力 › 記録の編集",
                variant: Self.label(size),
                to: "\(name).png"
            )
        }

        let itemModel = try await Self.model(
            .expense,
            digits: Self.itemDigits
        )

        Self.addItems(to: itemModel)

        let itemSlip = EntrySheet(model: itemModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Color(uiColor: .systemBackground))
            .environment(\.colorScheme, .light)

        try Self.write(itemSlip, title: "記録の入力 › 品目の入った紙のカード", to: "entry-item-slip.png")

        let itemSheet = EntryItemSheet(model: itemModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .light)

        try Self.write(itemSheet, title: "記録の入力 › 品目のシート", to: "entry-item-sheet.png")

        let itemInput = EntryItemSheet(model: itemModel, isSlipOpen: true)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .light)

        try Self.write(itemInput, title: "記録の入力 › 品目のシート › 紙のカードを開いた時", to: "entry-item-input.png")

        let includedModel = try await Self.model(
            .expense,
            digits: []
        )

        await includedModel.apply(Self.includedReading)

        let included = EntryItemSheet(model: includedModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .light)

        try Self.write(included, title: "記録の入力 › 品目のシート › 内税の品目", to: "entry-item-included.png")

        let emptySheet = EntryItemSheet(model: closedModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .dark)

        try Self.write(emptySheet, title: "記録の入力 › 品目のシート › 品目なし", to: "entry-item-empty.png")

        let help = EntryGuideCard(guide: .items) {}
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Palette.background)
            .environment(\.colorScheme, .light)

        try Self.write(help, title: "記録の入力 › 品目の使い方", to: "entry-item-help.png")

        try await renderReceipt()
        try await renderSaveLabels()
        try await renderVoice()
    }
}

private extension SnapshotTests {
    static let voiceCards: [(String, String, CGSize, (String, String))] = [
        ("empty", "聞き取りの待ち受け", phone, ("", "")),
        ("listening", "聞き取り中", phone, ("昨日、駅前でランチ980円、", "カードで")),
        ("long", "長い文", narrow, ("昨日の夜、駅前の居酒屋で会社の同期と送別会をして、二次会のカラオケも含めて一人", "5,800円を楽天カードで払った")),
        (
            "very-long",
            "とても長い文",
            narrow,
            (String(repeating: "今日は朝からスーパーで買い物をして、", count: 5), "合計3,240円")
        )
    ]

    func renderVoice() async throws {
        let today = LocalDate(snapshotNow, in: .current)

        for (name, title, size, text) in Self.voiceCards {
            let model = try await Self.model(.expense, digits: [])
            let source = VoiceSnapshotSource()
            let flow = EntryVoiceFlow(dependencies: .snapshot(source))

            await flow.start(for: model, today: today) {}
            source.say(settled: text.0, pending: text.1)

            if !text.0.isEmpty {
                source.speak()
            }

            let card = EntryVoiceCard(
                flow: flow,
                model: model,
                today: today,
                onCancel: {},
                onFinish: {},
                onOpenSettings: {}
            )
            .padding(16)
            .frame(width: size.width)
            .background(Palette.panel)
            .environment(\.colorScheme, .dark)

            try Self.write(
                card,
                title: "声の入力 › \(title)",
                variant: Self.label(size),
                to: "voice-card-\(name).png"
            )
        }

        let deniedModel = try await Self.model(.expense, digits: [])
        var denied = EntryVoiceFlow.Dependencies.snapshot(VoiceSnapshotSource())
        denied.requestPermission = { false }
        denied.isDenied = { true }
        let deniedFlow = EntryVoiceFlow(dependencies: denied)

        await deniedFlow.start(for: deniedModel, today: today) {}

        let deniedCard = EntryVoiceCard(
            flow: deniedFlow,
            model: deniedModel,
            today: today,
            onCancel: {},
            onFinish: {},
            onOpenSettings: {}
        )
        .padding(16)
        .frame(width: Self.phone.width)
        .background(Palette.panel)

        try Self.write(
            deniedCard,
            title: "声の入力 › マイクが使えない時",
            variant: Self.label(Self.phone),
            to: "voice-card-denied.png"
        )

        let notices: [(String, String, EntryVoiceFlow.Notice)] = [
            (
                "applied",
                "入れた",
                .init(outcome: .applied, count: 4, text: "昨日、駅前の喫茶店でモーニングセットとコーヒーのおかわりで980円、カードで")
            ),
            ("missing", "金額が読めない", .init(outcome: .missingAmount, count: 1, text: "昨日のコンビニ")),
            ("unheard", "聞こえない", .init(outcome: .unheard, count: 0, text: ""))
        ]

        for (name, title, notice) in notices {
            let view = EntryVoiceNotice(notice: notice, onUndo: {}, onClose: {})
                .padding(20)
                .frame(width: Self.narrow.width)
                .background(Palette.background)

            try Self.write(
                view,
                title: "声の入力 › 結果の知らせ › \(title)",
                to: "voice-notice-\(name).png"
            )
        }

        let listeningModel = try await Self.model(.expense, digits: [])
        let category = try #require(listeningModel.output.categories.first)

        let listeningSource = VoiceSnapshotSource()
        let listeningFlow = EntryVoiceFlow(dependencies: .snapshot(listeningSource))

        await listeningFlow.start(for: listeningModel, today: today) {}
        listeningSource.speak()

        let listening = EntrySlip(
            model: listeningModel,
            deck: .amount,
            today: today,
            isMemoActive: false,
            listening: listeningFlow,
            preview: VoiceReading(amount: 980, categoryId: category.id),
            growth: 0,
            onSelect: { _ in },
            onMemo: {},
            onOpenItems: {},
            onReceipt: nil,
            onVoice: nil
        )
        .background(Palette.card)
        .padding(20)
        .frame(width: Self.phone.width)
        .background(Palette.background)
        .environment(\.colorScheme, .dark)

        try Self.write(listening, title: "記録の入力 › 声を聞いている紙のカード", to: "voice-slip-listening.png")

        let appliedModel = try await Self.model(.expense, digits: [])
        let wallet = try #require(appliedModel.output.wallets.last)

        appliedModel.apply(VoiceReading(
            amount: 980,
            date: today.adding(days: -1),
            walletId: wallet.id,
            memo: "駅前でランチ"
        ))

        let applied = EntrySlip(
            model: appliedModel,
            deck: .amount,
            today: today,
            isMemoActive: false,
            listening: nil,
            preview: nil,
            growth: 0,
            onSelect: { _ in },
            onMemo: {},
            onOpenItems: {},
            onReceipt: {},
            onVoice: {}
        )
        .background(Palette.card)
        .padding(20)
        .frame(width: Self.phone.width)
        .background(Palette.background)

        try Self.write(applied, title: "記録の入力 › 声で入った紙のカード", to: "voice-slip-applied.png")
    }
}

@MainActor
private final class VoiceSnapshotSource: EntryVoiceSource {
    private var onEvent: (@MainActor (EntryVoiceEvent) -> Void)?

    func start(
        hints: [String],
        _ onEvent: @escaping @MainActor (EntryVoiceEvent) -> Void
    ) async throws {
        self.onEvent = onEvent
    }

    func finish() async {}

    func cancel() async {}

    func say(settled: String, pending: String) {
        onEvent?(.transcript(EntryVoiceTranscript(settled: settled, pending: pending)))
    }

    func speak() {
        for level in [0.2, 0.5, 0.9, 0.6, 0.3, 0.7, 1, 0.5, 0.8, 0.4, 0.6, 0.9] {
            onEvent?(.level(level))
        }
    }
}

@MainActor
private extension EntryVoiceFlow.Dependencies {
    static func snapshot(_ source: VoiceSnapshotSource) -> Self {
        Self(
            isAvailable: { true },
            isDenied: { false },
            requestPermission: { true },
            makeSource: { source },
            prepare: {},
            choose: { _ in nil },
            clock: .fixed(snapshotNow),
            silence: .seconds(60),
            noticeDuration: .seconds(60)
        )
    }
}

private extension SnapshotTests {
    func renderSaveLabels() async throws {
        let longModel = try await Self.model(
            .expense,
            digits: Self.largeDigits,
            hasTemplates: true,
            hasLongNames: true
        )

        for (name, size) in [("entry-long", Self.phone), ("entry-long-narrow", Self.narrow)] {
            let view = EntrySheet(model: longModel)
                .frame(width: size.width, height: size.height)
                .background(Palette.background)
                .environment(\.canScanReceipt, true)
                .environment(\.colorScheme, .light)

            try Self.write(
                view,
                title: "記録の入力 › 長い名前のテンプレートと口座",
                variant: Self.label(size),
                to: "\(name).png"
            )
        }

        let pastModel = try await Self.model(
            .expense,
            digits: Self.smallDigits,
            hasTemplates: true
        )

        pastModel.state.setDate(LocalDate(snapshotNow, in: .current).adding(days: -3))

        for (name, size) in [
            ("entry-past-date", Self.mini),
            ("entry-past-date-narrow", Self.narrow)
        ] {
            let view = EntrySheet(model: pastModel)
                .frame(width: size.width, height: size.height)
                .background(Palette.background)
                .environment(\.canScanReceipt, true)
                .environment(\.colorScheme, .dark)

            try Self.write(
                view,
                title: "記録の入力 › 過去の日付",
                variant: Self.label(size),
                to: "\(name).png"
            )
        }

        let transferModel = try await Self.model(
            .transfer,
            digits: Self.largeDigits,
            hasLongNames: true
        )

        transferModel.state.setFee(440)

        let transfer = EntrySheet(model: transferModel)
            .frame(width: Self.narrow.width, height: Self.narrow.height)
            .background(Palette.background)
            .environment(\.colorScheme, .light)

        try Self.write(
            transfer,
            title: "記録の入力 › 振替の手数料と長い口座名",
            variant: Self.label(Self.narrow),
            to: "entry-transfer-narrow.png"
        )
    }
}

private extension SnapshotTests {
    static let receiptThemes: [(ThemePreset, String)] = [
        (.white, "ホワイト"),
        (.black, "ブラック"),
        (.rose, "ローズ")
    ]

    func renderReceipt() async throws {
        let suspectModel = try await Self.model(
            .expense,
            digits: []
        )

        await suspectModel.apply(Self.suspectReading)

        let drawerModel = try await Self.model(
            .expense,
            digits: Self.smallDigits,
            hasTemplates: true
        )

        for (theme, label) in Self.receiptThemes {
            let palette = theme.palette
            let name = theme.rawValue

            let drawer = EntrySheet(model: drawerModel)
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Palette.background)
                .environment(\.canScanReceipt, true)

            let guide = EntryGuideCard(
                onConfirm: {},
                hidesNext: .constant(false),
                guide: .receipt
            ) {}
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Palette.background)

            let reading = EntryReceiptReadingCard()
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Palette.background)

            let suspect = EntryItemSheet(model: suspectModel)
                .frame(width: Self.phone.width, height: Self.phone.height)

            let buttons = HStack(spacing: 8) {
                EntryReceiptButton(freeLeft: 2) {}

                EntryReceiptButton(freeLeft: 0) {}

                EntryReceiptButton(freeLeft: nil) {}
            }
            .padding(24)
            .background(Palette.panel)

            let arts = HStack(spacing: 16) {
                EntryReceiptArt(kind: .flat)

                EntryReceiptArt(kind: .bright)

                EntryReceiptArt(kind: .edges)

                EntryReceiptArt(kind: .reading)
            }
            .padding(24)
            .background(Palette.panel)

            try Self.write(
                drawer.environment(\.palette, palette),
                title: "記録の入力 › レシートの読み取り › 入力シート",
                variant: "テーマ \(label)",
                to: "entry-receipt-drawer-\(name).png"
            )
            try Self.write(
                guide.environment(\.palette, palette),
                title: "レシートの読み取り › 案内のカード",
                variant: "テーマ \(label)",
                to: "entry-receipt-guide-\(name).png"
            )
            try Self.write(
                reading.environment(\.palette, palette),
                title: "レシートの読み取り › 読み取り中のカード",
                variant: "テーマ \(label)",
                to: "entry-receipt-reading-\(name).png"
            )
            try Self.write(
                suspect.environment(\.palette, palette),
                title: "記録の入力 › 品目のシート › 読み違えの候補",
                variant: "テーマ \(label)",
                to: "entry-item-suspect-\(name).png"
            )
            try Self.write(
                buttons.environment(\.palette, palette),
                title: "レシートの読み取り › ボタン（残り回数別）",
                variant: "テーマ \(label)",
                to: "entry-receipt-buttons-\(name).png"
            )
            try Self.write(
                arts.environment(\.palette, palette),
                title: "レシートの読み取り › 案内の絵",
                variant: "テーマ \(label)",
                to: "entry-receipt-arts-\(name).png"
            )
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let phone = CGSize(width: 393, height: 852)
    static let padForm = CGSize(width: 540, height: 620)
    static let short = CGSize(width: 375, height: 637)
    static let padPage = CGSize(width: 704, height: 790)
    static let padTall = CGSize(width: 704, height: 1130)
    static let mini = CGSize(width: 375, height: 812)
    static let tall = CGSize(width: 402, height: 874)
    static let max = CGSize(width: 440, height: 956)
    static let narrow = CGSize(width: 320, height: 693)

    static let smallDigits: [AmountCalculator.Key] = [.digit(1), .digit(2), .doubleZero]
    static let largeDigits = (2...9).reversed().map(AmountCalculator.Key.digit)
    static let itemDigits: [AmountCalculator.Key] = [.digit(6), .digit(6), .digit(6)]

    static let cases: [(String, String, Entry.Kind, [AmountCalculator.Key], EntryDeck)] = [
        ("entry-expense", "支出の金額", .expense, smallDigits, .amount),
        ("entry-category", "カテゴリの選択", .expense, [], .category),
        ("entry-wallet", "口座の選択", .expense, smallDigits, .wallet(.source)),
        ("entry-date", "日付の選択", .expense, smallDigits, .date),
        ("entry-transfer", "振替の金額", .transfer, smallDigits, .amount),
        ("entry-transfer-empty", "振替の口座の選択", .transfer, [], .transfer),
        ("entry-fee", "振替の手数料", .transfer, smallDigits, .fee),
        ("entry-expense-large", "支出の大きな金額", .expense, largeDigits, .amount)
    ]

    static let includedReading = ReceiptReading(
        store: "天然酵母の食パン専門店 つばめ&Milk名駅店",
        total: 3170,
        items: [
            EntryItem.Draft(name: "T/O オムレツサンド", amount: 780, taxRate: .reduced),
            EntryItem.Draft(name: "絹香食パン", amount: 890, taxRate: .reduced),
            EntryItem.Draft(name: "スイートポテト", amount: 1500, taxRate: .reduced)
        ],
        taxIncluded: true
    )

    static let suspectReading = ReceiptReading(
        store: "スーパー青葉 横浜店",
        total: 1446,
        items: [
            EntryItem.Draft(name: "牛乳", quantity: 2, amount: 396),
            EntryItem.Draft(name: "食パン", amount: 220),
            EntryItem.Draft(name: "たまご", amount: 278),
            EntryItem.Draft(name: "バナナ", amount: 198),
            EntryItem.Draft(name: "ヨーグルト", amount: 414)
        ]
    )

    static func label(
        _ size: CGSize,
        isDark: Bool = false,
        isLarge: Bool = false
    ) -> String {
        var parts = ["幅 \(Int(size.width))", "高さ \(Int(size.height))", isDark ? "ダーク" : "ライト"]

        if isLarge {
            parts.append("文字大")
        }

        return parts.joined(separator: "・")
    }

    static func model(
        _ type: Entry.Kind,
        digits: [AmountCalculator.Key],
        hasTemplates: Bool = false,
        hasLongNames: Bool = false
    ) async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = snapshotNow
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        if hasTemplates {
            let options = try await database.entryOptions()

            for (name, amount) in [("ランチ", 900), ("コーヒー", 380), ("電車", 440)] {
                let draft = EntryTemplateDraft(
                    name: name,
                    type: .expense,
                    amount: amount,
                    categoryId: options.expenseCategories.first?.id,
                    walletId: options.wallets.first?.id
                )

                _ = try await database.saveTemplate(draft, at: now)
            }
        }

        if hasLongNames {
            try await renameLong(in: database, at: now)
        }

        let model = EntryModel(
            parts: ScreenParts(database: database, clock: .fixed(snapshotNow)),
            date: date,
            type: type
        )

        await model.load()

        for key in digits {
            model.state.press(key)
        }

        return model
    }

    static func startModel() async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = snapshotNow
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let options = try await database.entryOptions()

        let templates: [(String, Int?)] = [("子どもの習い事の月謝", 12000), ("電車", nil), ("コーヒー", 380)]

        for (name, amount) in templates {
            let template = EntryTemplateDraft(
                name: name,
                type: .expense,
                amount: amount,
                categoryId: options.expenseCategories.first?.id,
                walletId: options.wallets.last?.id
            )

            _ = try await database.saveTemplate(template, at: now)
        }

        let entries = [(980, "ランチ", -1), (220, "", -1), (1540, "ドラッグストア", -2)]

        for (index, (amount, memo, offset)) in entries.enumerated() {
            let savedAt = snapshotNow.addingTimeInterval(TimeInterval(index - entries.count))

            let draft = EntryModel(
                parts: ScreenParts(database: database, clock: .fixed(savedAt)),
                date: date.adding(days: offset)
            )

            await draft.load()

            draft.state.memo = memo

            for character in String(amount) {
                draft.state.press(.digit(Int(String(character)) ?? 0))
            }

            _ = try #require(await draft.save())
        }

        let model = EntryModel(
            parts: ScreenParts(database: database, clock: .fixed(snapshotNow)),
            date: date
        )

        await model.load()
        await model.reloadCategories()

        return model
    }

    static func editingModel() async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = snapshotNow
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let draft = EntryModel(
            parts: ScreenParts(database: database, clock: .fixed(snapshotNow)),
            date: date
        )

        await draft.load()

        for key in smallDigits {
            draft.state.press(key)
        }

        let saved = try #require(await draft.save())
        let model = EntryModel(
            parts: ScreenParts(database: database, clock: .fixed(snapshotNow)),
            editing: saved.entry.id,
            date: date
        )

        await model.load()

        return model
    }

    static func renameLong(
        in database: AppDatabase,
        at now: Date
    ) async throws {
        let options = try await database.entryOptions()
        let category = try #require(options.expenseCategories.first)
        let categoryIcon = try #require(options.icons[category.iconId])
        let wallet = try #require(options.wallets.first)
        let walletIcon = try #require(options.icons[wallet.iconId])

        var categoryDraft = EntryCategoryDraft(category, icon: categoryIcon)
        var walletDraft = WalletDraft(wallet, icon: walletIcon)

        categoryDraft.name = "子どもの習い事と教材と遠足の費用"
        walletDraft.name = "三井住友カード ゴールド 家族カード"

        try await database.saveCategory(categoryDraft, tags: [], editing: category.id, at: now)
        try await database.save(walletDraft, editing: wallet.id, at: now)
    }

    static func addItems(to model: EntryModel) {
        model.state.memo = "スーパー山田"
        model.state.addItem(name: "牛乳", quantity: 2, amount: 396, taxRate: .reduced)
        model.state.addItem(name: "食パン", amount: 250, taxRate: .reduced)
        model.state.addItem(name: "洗剤", amount: 398, taxRate: .standard)
        model.state.addItem(name: "シール値引", amount: -30, taxRate: .standard)
        model.state.addItem(name: "弁当", amount: 540)
    }

    static func write(
        _ view: some View,
        title: String,
        variant: String = "",
        to name: String
    ) throws {
        let renderer = ImageRenderer(content: view)

        renderer.scale = 2

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: name)

        try data.write(to: url)

        try SnapshotIndex.record(directory: directory, file: name, title: title, variant: variant)
    }
}
