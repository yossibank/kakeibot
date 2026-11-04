import Core
@testable import DesignSystem
@testable import Features
import SwiftUI
import Testing
import UIKit

@MainActor
struct SnapshotTests {
    @Test
    func render() throws {
        let now = Date()
        let names = ["みずほ銀行 普通預金", "楽天カード", "PayPay", "三井住友カード ゴールド", "現金", "ゆうちょ銀行 貯金"]
        let wallets = names.enumerated().map { index, name in
            Wallet(
                name: name,
                kind: .bank,
                iconId: Icon.ID(),
                initialBalance: 0,
                sortOrder: index,
                createdAt: now,
                updatedAt: now
            )
        }

        let grid = SettingsTileGrid(items: wallets, columns: 2, spacing: 8) { wallet in
            SettingsWalletTile(wallet: wallet, icon: nil, isSelected: wallet.id == wallets[0].id) {}
        }
        .padding(20)

        for variant in Self.variants {
            try Self.write(grid, variant: variant, to: "wallet-tiles")
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
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let maxHeight: CGFloat = 2400

    static let variants = [
        Variant(name: "regular", width: 393, scheme: .light, textSize: .standard),
        Variant(name: "narrow", width: 320, scheme: .dark, textSize: .large)
    ]

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
