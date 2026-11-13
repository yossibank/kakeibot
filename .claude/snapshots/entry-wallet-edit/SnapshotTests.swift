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
        let model = try await Self.model()

        let view = EntrySheet(model: model, deck: .wallet(.source))
            .frame(width: Self.phone.width, height: Self.phone.height)
            .background(Color(uiColor: .systemBackground))
            .environment(\.colorScheme, .light)

        try Self.write(view, to: "wallet-edit.png")

        let database = try AppDatabase.inMemory()

        for kind in [Wallet.Kind.cash, .card] {
            for (variant, width, textSize) in Self.variants {
                let sheet = WalletEditSheet(
                    model: WalletEditModel(
                        database: database,
                        kind: kind
                    )
                )

                let style = ThemeStyle(
                    corner: .standard,
                    displayFont: .mincho,
                    textFont: .gothic,
                    textSize: textSize
                )

                let form = SettingsFormCard {
                    sheet.kindChooser

                    sheet.balanceField
                }
                .padding(20)
                .frame(width: width)
                .background(Palette.background)
                .environment(\.themeStyle, style)
                .environment(\.colorScheme, .light)

                try Self.write(form, to: "wallet-kind-\(kind.rawValue)-\(variant).png")
            }
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let phone = CGSize(width: 393, height: 852)

    static let variants: [(String, CGFloat, ThemeTextSize)] = [
        ("regular", 393, .standard),
        ("narrow", 320, .large)
    ]

    static func model() async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let model = EntryModel(database: database, date: date, type: .expense)

        await model.load()

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
