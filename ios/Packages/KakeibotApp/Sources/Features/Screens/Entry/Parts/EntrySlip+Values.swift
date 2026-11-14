import Core
import DesignSystem
import SwiftUI

extension EntrySlip {
    static let waveHeight: CGFloat = 16
    static let amountHeight: CGFloat = 60
    static let amountGrowth: CGFloat = 24
    static let amountSize: CGFloat = 36
    static let amountSizeGrowth: CGFloat = 8
    static let rowHeight: CGFloat = 44
    static let rowGrowth: CGFloat = 12
    static let memoGrowth: CGFloat = 8
    static let fieldCount: CGFloat = 3
    static let markSize: CGFloat = 24
    static let quickSize: CGFloat = 32
    static let badgeSize: CGFloat = 16

    static var growthLimit: CGFloat {
        fieldCount * rowGrowth + amountGrowth + memoGrowth
    }

    static var amountGold: LinearGradient {
        LinearGradient(
            colors: [Palette.accentStrong, Palette.accent],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var gold: LinearGradient {
        LinearGradient(
            colors: [Palette.accentStrong, Palette.accent, Palette.accentDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.mix(with: Palette.cardTop, by: 0.84),
                Palette.cardTop,
                Palette.cardBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var litFill: LinearGradient {
        LinearGradient(
            colors: [Palette.accent.opacity(.soft), .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    static var shine: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.3), location: 0),
                .init(color: .clear, location: 0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var stretch: CGFloat {
        min(max(growth / Self.growthLimit, 0), 1)
    }

    var fieldHeight: CGFloat {
        Self.rowHeight + Self.rowGrowth * stretch
    }

    var amountRowHeight: CGFloat {
        Self.amountHeight + Self.amountGrowth * stretch
    }

    var memoHeight: CGFloat {
        Self.rowHeight + Self.memoGrowth * stretch
    }

    var amountSize: CGFloat {
        Self.amountSize + Self.amountSizeGrowth * stretch
    }

    var idleAmountColor: Color {
        shownAmount > 0 ? Palette.text : Palette.hint
    }

    var routeValue: String {
        guard
            let source = model.wallet(model.walletId)?.name,
            let destination = model.wallet(model.toWalletId)?.name
        else {
            return "口座を選ぶ"
        }

        return "\(source) → \(destination)"
    }

    var feeValue: String {
        model.fee > 0 ? AmountText.text(model.fee) : "なし"
    }

    var dateValue: String {
        let day = EntryModel.shortDateText(for: model.date, today: today)
        return "\(day)（\(model.date.weekday.shortName)）"
    }

    var memoText: String {
        model.memo.isEmpty ? "\(model.memoPrompt)をメモ" : model.memo
    }

    var memoColor: Color {
        if isMemoActive {
            return Palette.accent
        }

        return model.memo.isEmpty ? Palette.hint : Palette.subtext
    }

    var showsItems: Bool {
        model.showsItems && !model.items.isEmpty
    }

    var shownCategory: EntryCategory? {
        guard
            isListening,
            let id = preview?.categoryId,
            let category = model.categories.first(where: { $0.id == id })
        else {
            return model.selectedCategory
        }

        return category
    }

    var shownAmount: Int {
        if isListening, let amount = preview?.amount {
            return amount
        }

        return model.amount
    }

    var isListening: Bool {
        listening != nil
    }

    func isSelected(_ target: EntryDeck) -> Bool {
        deck.field(for: model.type) == target
    }
}
