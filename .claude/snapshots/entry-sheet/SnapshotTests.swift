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

        let emptySheet = EntryItemSheet(model: closedModel)
            .frame(width: Self.phone.width, height: Self.phone.height)
            .environment(\.colorScheme, .dark)

        try Self.write(emptySheet, to: "entry-item-empty.png")

        let help = EntryItemHelp {}
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Palette.background)
            .environment(\.colorScheme, .light)

        try Self.write(help, to: "entry-item-help.png")
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
        model.addItem(name: "牛乳", quantity: 2, amount: 396)
        model.addItem(name: "食パン", amount: 250)
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
