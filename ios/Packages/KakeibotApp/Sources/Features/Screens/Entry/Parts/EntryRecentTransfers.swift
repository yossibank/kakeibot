import Core
import DesignSystem
import SwiftUI

struct EntryRecentTransfers: View {
    let model: EntryModel
    let transfers: [Entry]
    let today: LocalDate
    let onUse: (Entry) -> Void

    var body: some View {
        EntryRecentRow(title: "最近の振替") {
            ForEach(transfers) { transfer in
                EntryRecentCard(
                    title: route(transfer),
                    amount: transfer.amount,
                    detail: detail(transfer),
                    onUse: {
                        onUse(transfer)
                    },
                    mark: {
                        Image(systemName: "arrow.left.arrow.right")
                            .textFont(.caption2, weight: .bold)
                            .foregroundStyle(Palette.accent)
                    }
                )
            }
        }
    }
}

private extension EntryRecentTransfers {
    func route(_ transfer: Entry) -> String {
        let source = model.wallet(transfer.walletId)?.name ?? ""
        let destination = model.wallet(transfer.toWalletId)?.name ?? ""
        return "\(source) → \(destination)"
    }

    func detail(_ transfer: Entry) -> String {
        let fee = model.fee(of: transfer)
        let day = EntryModel.shortDateText(for: transfer.date, today: today)

        guard fee > 0 else {
            return day
        }

        return "\(day) · 手数料 \(AmountText.text(fee))"
    }
}
