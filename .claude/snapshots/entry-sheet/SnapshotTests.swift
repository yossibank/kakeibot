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
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let phone = CGSize(width: 393, height: 852)

    static let smallDigits: [AmountCalculator.Key] = [.digit(1), .digit(2), .doubleZero]
    static let largeDigits = (2...9).reversed().map(AmountCalculator.Key.digit)

    static let cases: [(String, Entry.Kind, [AmountCalculator.Key])] = [
        ("entry-expense", .expense, smallDigits),
        ("entry-transfer", .transfer, smallDigits),
        ("entry-expense-large", .expense, largeDigits)
    ]

    static func model(
        _ type: Entry.Kind,
        digits: [AmountCalculator.Key]
    ) async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let model = EntryModel(database: database, date: date, type: type)

        await model.load()

        for key in digits {
            model.press(key)
        }

        return model
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
