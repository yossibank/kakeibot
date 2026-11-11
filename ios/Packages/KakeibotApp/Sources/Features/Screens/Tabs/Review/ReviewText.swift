import Core
import DesignSystem
import SwiftUI

enum ReviewText {
    static func shares(_ amounts: [Int]) -> [String?] {
        let whole = amounts.reduce(0, +)
        let percents = Percent.shares(amounts)

        return zip(amounts, percents).map { amount, percent in
            share(
                amount,
                percent: percent,
                whole: whole
            )
        }
    }

    static func budget(_ usage: BudgetUsage) -> String {
        if usage.isOver {
            return "\(AmountText.text(-usage.remaining)) オーバー"
        }

        let percent = Percent.floor(usage.spent, of: usage.budget)

        return "予算の \(percent)%"
    }

    static func balanceTitle(_ amount: Int) -> String {
        if amount > 0 {
            return "収支 · 黒字"
        }

        return amount < 0 ? "収支 · 赤字" : "収支"
    }

    static func balanceColor(_ amount: Int) -> Color {
        if amount > 0 {
            return Palette.accent
        }

        return amount < 0 ? Palette.rose : Palette.accentStrong
    }
}

private extension ReviewText {
    static func share(
        _ amount: Int,
        percent: Int,
        whole: Int
    ) -> String? {
        guard
            amount > 0,
            whole > 0
        else {
            return "0%"
        }

        if amount * 100 < whole {
            return nil
        }

        if percent >= 100,
           amount < whole {
            let tenths = amount * 1000 / whole
            return "\(tenths / 10).\(tenths % 10)%"
        }

        return "\(percent)%"
    }
}
