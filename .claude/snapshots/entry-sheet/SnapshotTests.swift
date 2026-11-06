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
        for (name, type, digits) in Self.cases {
            let model = try await Self.model(type, digits: digits)

            let view = EntrySheet(model: model)
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Color(uiColor: .systemBackground))
                .environment(\.colorScheme, .light)

            try Self.write(view, to: "\(name).png")
        }

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
            digits: Self.smallDigits,
            startsWithAmount: false
        )

        let closed = EntrySheet(model: closedModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Color(uiColor: .systemBackground))
            .environment(\.colorScheme, .light)

        try Self.write(closed, to: "entry-closed.png")

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
            digits: Self.itemDigits,
            startsWithAmount: false
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
            digits: [],
            startsWithAmount: false
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
            startsWithAmount: false,
            hasLongNames: true
        )

        transferModel.setFee(440)

        let transfer = EntrySheet(model: transferModel)
            .frame(width: Self.narrow.width, height: Self.narrow.height)
            .background(Palette.background)
            .environment(\.colorScheme, .light)

        try Self.write(transfer, to: "entry-transfer-narrow.png")

        let longClosedModel = try await Self.model(
            .expense,
            digits: Self.largeDigits,
            startsWithAmount: false,
            hasLongNames: true
        )

        let labels = VStack(spacing: 16) {
            EntrySaveButton(label: longClosedModel.saveLabel(today: longClosedModel.date)) {}

            EntrySaveButton(label: transferModel.saveLabel(today: transferModel.date)) {}

            EntrySaveButton(label: EntryModel.SaveLabel(
                title: "変更を保存",
                amount: "¥1,200",
                category: "食費",
                day: "昨日",
                wallets: "財布"
            )) {}

            EntrySaveButton(label: EntryModel.SaveLabel(title: "金額を入れてください")) {}
                .disabled(true)

            EntrySaveButton(label: EntryModel.SaveLabel(title: "振替先を選んでください")) {}
                .disabled(true)
        }
        .padding(16)
        .frame(width: 168 + 32)
        .background(Palette.background)
        .environment(\.colorScheme, .light)

        try Self.write(labels, to: "entry-save-labels-168.png")
    }
}

private extension SnapshotTests {
    static let receiptThemes: [ThemePreset] = [.white, .black, .rose]

    func renderReceipt() async throws {
        let suspectModel = try await Self.model(
            .expense,
            digits: [],
            startsWithAmount: false
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

    static let cases: [(String, Entry.Kind, [AmountCalculator.Key])] = [
        ("entry-expense", .expense, smallDigits),
        ("entry-transfer", .transfer, smallDigits),
        ("entry-transfer-empty", .transfer, []),
        ("entry-expense-large", .expense, largeDigits)
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
        startsWithAmount: Bool = true,
        hasTemplates: Bool = false,
        hasLongNames: Bool = false
    ) async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)
        try await database.setSetting(.entryStartsWithAmount, to: startsWithAmount)

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
