import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension AssetsView {
    @ViewBuilder
    func debtDetail(of row: AssetsModel.WalletRow) -> some View {
        let bills = row.bills.filter { $0.amount > 0 }

        if row.wallet.kind == .card,
           !bills.isEmpty {
            AssetsBillSchedule(
                bills: bills,
                showsAmounts: Self.showsBillAmounts(bills, balance: row.balance)
            )
            .padding(.top, 2)
        }

        if let ratio = row.repaidRatio,
           let percent = row.repaidPercent {
            HStack(spacing: 8) {
                RatioBar(ratio, tint: Palette.accent)

                Text("\(percent)% 返した")
                    .textFont(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize()
            }
        }

        if case let .until(payoff) = row.repayment {
            AssetsDebtChip(
                systemImage: "arrow.triangle.2.circlepath",
                text: Self.payoffText(payoff)
            )
        } else if let note = plainNote(of: row) {
            Text(note)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

private extension AssetsView {
    static func showsBillAmounts(
        _ bills: [CardBill],
        balance: Int
    ) -> Bool {
        bills.count > 1 || bills.first?.amount != -balance
    }

    static func repaymentText(_ repayment: AssetsModel.Repayment) -> String? {
        switch repayment {
        case .unset: "返済は未設定"
        case .finished: "返し終わりました"
        case .open: "返し終わる時期は未定"
        case .until: nil
        }
    }

    static func payoffText(_ payoff: LoanPayoff) -> String {
        let date = payoff.lastDate
        return "あと \(payoff.count) 回 · \(String(date.year))/\(date.month) まで"
    }

    func plainNote(of row: AssetsModel.WalletRow) -> String? {
        if let repayment = row.repayment {
            return Self.repaymentText(repayment)
        }

        guard
            row.wallet.kind == .card,
            row.bills.isEmpty
        else {
            return nil
        }

        return "引き落としは未設定"
    }
}
