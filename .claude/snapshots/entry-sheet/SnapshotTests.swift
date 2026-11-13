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
        for (name, type, digits, deck) in Self.cases {
            let model = try await Self.model(type, digits: digits)

            let view = EntrySheet(model: model, deck: deck)
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Color(uiColor: .systemBackground))
                .environment(\.colorScheme, .light)

            try Self.write(view, to: "\(name).png")

            let dark = EntrySheet(model: model, deck: deck)
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Palette.background)
                .environment(\.canScanReceipt, true)
                .environment(\.palette, ThemePreset.black.palette)

            try Self.write(dark, to: "\(name)-dark.png")
        }

        let startModel = try await Self.startModel()

        let start = EntrySheet(model: startModel, deck: .category)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Palette.background)
            .environment(\.canScanReceipt, true)

        try Self.write(start, to: "entry-start.png")

        let startDark = EntrySheet(model: startModel, deck: .category)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Palette.background)
            .environment(\.canScanReceipt, true)
            .environment(\.palette, ThemePreset.black.palette)

        try Self.write(startDark, to: "entry-start-dark.png")

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

        try Self.write(mini, to: "entry-mini-large.png")

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

            try Self.write(edit, to: "\(name).png")
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

        try Self.write(itemSlip, to: "entry-item-slip.png")

        let itemSheet = EntryItemSheet(model: itemModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .light)

        try Self.write(itemSheet, to: "entry-item-sheet.png")

        let itemInput = EntryItemSheet(model: itemModel, isSlipOpen: true)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .light)

        try Self.write(itemInput, to: "entry-item-input.png")

        let includedModel = try await Self.model(
            .expense,
            digits: []
        )

        await includedModel.apply(Self.includedReading)

        let included = EntryItemSheet(model: includedModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .light)

        try Self.write(included, to: "entry-item-included.png")

        let emptySheet = EntryItemSheet(model: closedModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .dark)

        try Self.write(emptySheet, to: "entry-item-empty.png")

        let help = EntryGuideCard(guide: .items) {}
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Palette.background)
            .environment(\.colorScheme, .light)

        try Self.write(help, to: "entry-item-help.png")

        try await renderReceipt()
        try await renderSaveLabels()
        try await renderVoice()
    }
}

private extension SnapshotTests {
    static let voiceCards: [(String, CGSize, (String, String))] = [
        ("empty", phone, ("", "")),
        ("listening", phone, ("昨日、駅前でランチ980円、", "カードで")),
        ("long", narrow, ("昨日の夜、駅前の居酒屋で会社の同期と送別会をして、二次会のカラオケも含めて一人", "5,800円を楽天カードで払った")),
        ("very-long", narrow, (String(repeating: "今日は朝からスーパーで買い物をして、", count: 5), "合計3,240円"))
    ]

    func renderVoice() async throws {
        let today = LocalDate(Date(), in: .current)

        for (name, size, text) in Self.voiceCards {
            let model = try await Self.model(.expense, digits: [])
            let source = VoiceSnapshotSource()
            let flow = EntryVoiceFlow(dependencies: .snapshot(source))

            await flow.start(for: model, today: today) {}
            source.say(settled: text.0, pending: text.1)

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

            try Self.write(card, to: "voice-card-\(name).png")
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

        try Self.write(deniedCard, to: "voice-card-denied.png")

        let notices: [(String, EntryVoiceFlow.Notice)] = [
            (
                "applied",
                .init(outcome: .applied, count: 4, text: "昨日、駅前の喫茶店でモーニングセットとコーヒーのおかわりで980円、カードで")
            ),
            ("missing", .init(outcome: .missingAmount, count: 1, text: "昨日のコンビニ")),
            ("unheard", .init(outcome: .unheard, count: 0, text: ""))
        ]

        for (name, notice) in notices {
            let view = EntryVoiceNotice(notice: notice, onUndo: {}, onClose: {})
                .padding(20)
                .frame(width: Self.narrow.width)
                .background(Palette.background)

            try Self.write(view, to: "voice-notice-\(name).png")
        }

        let listeningModel = try await Self.model(.expense, digits: [])
        let category = try #require(listeningModel.categories.first)

        let listening = EntrySlip(
            model: listeningModel,
            deck: .amount,
            today: today,
            isMemoActive: false,
            isListening: true,
            preview: VoiceReading(amount: 980, categoryId: category.id),
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

        try Self.write(listening, to: "voice-slip-listening.png")

        let appliedModel = try await Self.model(.expense, digits: [])
        let wallet = try #require(appliedModel.wallets.last)

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
            isListening: false,
            preview: nil,
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

        try Self.write(applied, to: "voice-slip-applied.png")
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

            try Self.write(view, to: "\(name).png")
        }

        let pastModel = try await Self.model(
            .expense,
            digits: Self.smallDigits,
            hasTemplates: true
        )

        pastModel.date = LocalDate(Date(), in: .current).adding(days: -3)

        for (name, size) in [
            ("entry-past-date", Self.mini),
            ("entry-past-date-narrow", Self.narrow)
        ] {
            let view = EntrySheet(model: pastModel)
                .frame(width: size.width, height: size.height)
                .background(Palette.background)
                .environment(\.canScanReceipt, true)
                .environment(\.colorScheme, .dark)

            try Self.write(view, to: "\(name).png")
        }

        let transferModel = try await Self.model(
            .transfer,
            digits: Self.largeDigits,
            hasLongNames: true
        )

        transferModel.setFee(440)

        let transfer = EntrySheet(model: transferModel)
            .frame(width: Self.narrow.width, height: Self.narrow.height)
            .background(Palette.background)
            .environment(\.colorScheme, .light)

        try Self.write(transfer, to: "entry-transfer-narrow.png")
    }
}

private extension SnapshotTests {
    static let receiptThemes: [ThemePreset] = [.white, .black, .rose]

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

        for theme in Self.receiptThemes {
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
                to: "entry-receipt-drawer-\(name).png"
            )
            try Self.write(
                guide.environment(\.palette, palette),
                to: "entry-receipt-guide-\(name).png"
            )
            try Self.write(
                reading.environment(\.palette, palette),
                to: "entry-receipt-reading-\(name).png"
            )
            try Self.write(
                suspect.environment(\.palette, palette),
                to: "entry-item-suspect-\(name).png"
            )
            try Self.write(
                buttons.environment(\.palette, palette),
                to: "entry-receipt-buttons-\(name).png"
            )
            try Self.write(
                arts.environment(\.palette, palette),
                to: "entry-receipt-arts-\(name).png"
            )
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let phone = CGSize(width: 393, height: 852)
    static let mini = CGSize(width: 375, height: 812)
    static let narrow = CGSize(width: 320, height: 693)

    static let smallDigits: [AmountCalculator.Key] = [.digit(1), .digit(2), .doubleZero]
    static let largeDigits = (2...9).reversed().map(AmountCalculator.Key.digit)
    static let itemDigits: [AmountCalculator.Key] = [.digit(6), .digit(6), .digit(6)]

    static let cases: [(String, Entry.Kind, [AmountCalculator.Key], EntryDeck)] = [
        ("entry-expense", .expense, smallDigits, .amount),
        ("entry-category", .expense, [], .category),
        ("entry-wallet", .expense, smallDigits, .wallet(.source)),
        ("entry-date", .expense, smallDigits, .date),
        ("entry-transfer", .transfer, smallDigits, .amount),
        ("entry-transfer-empty", .transfer, [], .transfer),
        ("entry-fee", .transfer, smallDigits, .fee),
        ("entry-expense-large", .expense, largeDigits, .amount)
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

    static func model(
        _ type: Entry.Kind,
        digits: [AmountCalculator.Key],
        hasTemplates: Bool = false,
        hasLongNames: Bool = false
    ) async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
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

        let model = EntryModel(database: database, date: date, type: type)

        await model.load()

        for key in digits {
            model.press(key)
        }

        return model
    }

    static func startModel() async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
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

        for (amount, memo, offset) in [(980, "ランチ", -1), (220, "", -1), (1540, "ドラッグストア", -2)] {
            let draft = EntryModel(database: database, date: date.adding(days: offset))

            await draft.load()

            draft.memo = memo

            for character in String(amount) {
                draft.press(.digit(Int(String(character)) ?? 0))
            }

            _ = try #require(await draft.save())
        }

        let model = EntryModel(database: database, date: date)

        await model.load()
        await model.reloadCategories()

        return model
    }

    static func editingModel() async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let draft = EntryModel(database: database, date: date)

        await draft.load()

        for key in smallDigits {
            draft.press(key)
        }

        let saved = try #require(await draft.save())
        let model = EntryModel(database: database, editing: saved.entry.id, date: date)

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
        try await database.saveWallet(walletDraft, editing: wallet.id, at: now)
    }

    static func addItems(to model: EntryModel) {
        model.memo = "スーパー山田"
        model.addItem(name: "牛乳", quantity: 2, amount: 396, taxRate: .reduced)
        model.addItem(name: "食パン", amount: 250, taxRate: .reduced)
        model.addItem(name: "洗剤", amount: 398, taxRate: .standard)
        model.addItem(name: "シール値引", amount: -30, taxRate: .standard)
        model.addItem(name: "弁当", amount: 540)
    }

    static func write(
        _ view: some View,
        to name: String
    ) throws {
        let renderer = ImageRenderer(content: view)

        renderer.scale = 2

        let data = try #require(renderer.uiImage?.pngData())
        let url = URL(fileURLWithPath: directory).appending(path: name)

        try data.write(to: url)
    }
}
