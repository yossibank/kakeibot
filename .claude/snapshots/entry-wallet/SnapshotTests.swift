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

        try Self.write(view, to: "wallet.png")
    }

    @Test
    func renderCard() async throws {
        let model = try await Self.model(withCard: true)

        try Self.write(Self.sheet(model), to: "wallet-card.png")

        let later = try #require(model.billChoices.dropFirst().first?.date)

        model.selectBill(later)

        try Self.write(Self.sheet(model), to: "wallet-card-shifted.png")
    }
}

private extension SnapshotTests {
    static let directory = "__OUT__"
    static let phone = CGSize(width: 393, height: 852)

    static func sheet(_ model: EntryModel) -> some View {
        EntrySheet(model: model, deck: .wallet(.source))
            .frame(width: phone.width, height: phone.height)
            .background(Color(uiColor: .systemBackground))
            .environment(\.colorScheme, .light)
    }

    static func model(withCard: Bool = false) async throws -> EntryModel {
        let database = try AppDatabase.inMemory()
        let now = Date()
        let date = LocalDate(now, in: .current)

        try database.insertDefaultsIfEmpty(at: now)

        let card = withCard ? try await addCard(to: database, from: date) : nil
        let model = EntryModel(database: database, date: date, type: .expense)

        await model.load()

        if let card {
            model.walletId = card.id
        }

        return model
    }

    static func addCard(
        to database: AppDatabase,
        from date: LocalDate
    ) async throws -> Wallet {
        let options = try await database.entryOptions()
        let bank = options.wallets.first { $0.kind == .bank }

        let wallet = WalletDraft(
            kind: .card,
            name: "楽天カード",
            mark: .glyph(.card),
            color: "#4A6FA5",
            initialBalance: 0
        )

        let card = try await database.saveWallet(wallet, at: Date())

        let recurring = RecurringDraft(
            type: .transfer,
            amount: 0,
            categoryId: nil,
            walletId: bank?.id,
            toWalletId: card.id,
            frequency: .monthly,
            month: 1,
            day: 26,
            closingDay: 15,
            startDate: date
        )

        _ = try await database.saveRecurring(recurring, today: date, at: Date())

        return card
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
