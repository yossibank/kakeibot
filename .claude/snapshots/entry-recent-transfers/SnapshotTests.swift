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
        let transfers = model.recentTransfers

        for (suffix, preset) in [("light", ThemePreset.white), ("dark", .black)] {
            let view = EntryRecentTransfers(model: model, transfers: transfers) { _ in }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(width: Self.width)
                .background(Palette.background)
                .environment(\.palette, preset.palette)

            try Self.write(view, to: "recent-\(suffix).png")
        }
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let width: CGFloat = 393

    static func model() async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let bankDraft = WalletDraft(
            kind: .bank,
            name: "三井住友カード（NL）ゴールド",
            mark: .glyph(.bank),
            color: "#4A6FA5",
            initialBalance: 100_000
        )

        let payDraft = WalletDraft(
            kind: .cash,
            name: "楽天銀行 普通預金",
            mark: .glyph(.card),
            color: "#E07A5F",
            initialBalance: 0
        )

        let bank = try await database.saveWallet(bankDraft, at: now)
        let pay = try await database.saveWallet(payDraft, at: now)

        let options = try await database.entryOptions()

        let transfers = [
            (bank.id, pay.id, 10000, 110),
            (bank.id, pay.id, 30000, 1100),
            (options.wallets[1].id, options.wallets[0].id, 3000, 0)
        ]

        for (index, (source, destination, amount, fee)) in transfers.enumerated() {
            let draft = EntryDraft(
                type: .transfer,
                amount: amount,
                date: date,
                categoryId: nil,
                walletId: source,
                toWalletId: destination,
                fee: fee
            )

            let offset = TimeInterval(-index)
            let createdAt = now.addingTimeInterval(offset)

            try await database.saveEntry(draft, at: createdAt)
        }

        let model = EntryModel(database: database, date: date, type: .transfer)

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
