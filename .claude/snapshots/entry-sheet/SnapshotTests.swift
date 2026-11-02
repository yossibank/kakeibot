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

        let drawerModel = try await Self.model(.expense, digits: Self.smallDigits)

        for theme in Self.receiptThemes {
            let palette = theme.palette
            let name = theme.rawValue

            let drawer = EntrySheet(model: drawerModel)
                .frame(width: Self.phone.width, height: Self.phone.height)
                .background(Palette.background)
                .environment(\.canScanReceipt, true)

            let guide = EntryGuideCard(onConfirm: {}, guide: .receipt) {}
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

    static let smallDigits: [AmountCalculator.Key] = [.digit(1), .digit(2), .doubleZero]
    static let largeDigits = (2...9).reversed().map(AmountCalculator.Key.digit)
    static let itemDigits: [AmountCalculator.Key] = [.digit(6), .digit(6), .digit(6)]

    static let cases: [(String, Entry.Kind, [AmountCalculator.Key])] = [
        ("entry-expense", .expense, smallDigits),
        ("entry-transfer", .transfer, smallDigits),
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
        startsWithAmount: Bool = true
    ) async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)
        try await database.setSetting(.entryStartsWithAmount, to: startsWithAmount)

        let model = EntryModel(database: database, date: date, type: type)

        await model.load()

        for key in digits {
            model.press(key)
        }

        return model
    }

    static func addItems(to model: EntryModel) {
        model.memo = "スーパー山田"
        model.addItem(name: "牛乳", quantity: 2, amount: 396, taxRate: .reduced)
        model.addItem(name: "食パン", amount: 250, taxRate: .reduced)
        model.addItem(name: "洗剤", amount: 398, taxRate: .standard)
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
