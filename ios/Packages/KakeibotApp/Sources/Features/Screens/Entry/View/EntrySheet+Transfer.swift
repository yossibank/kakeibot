import Core
import DesignSystem
import Store
import SwiftUI

extension EntrySheet {
    var transferArea: some View {
        VStack(spacing: 12) {
            EntryTransferPanel(model: model) { role in
                open(.wallet(role))
            }

            if !isFormDeferred {
                transferExtras
            }
        }
    }

    var transferExtras: some View {
        VStack(spacing: 12) {
            EntryRouteRow(model: model) { route in
                withAnimation(.snappy) {
                    model.applyRoute(route)
                }
            }

            let transfers = model.recentTransfers

            if transfers.isEmpty {
                Text("チャージ・カードの支払い・口座のあいだの移動")
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            } else {
                EntryRecentTransfers(model: model, transfers: transfers) { transfer in
                    withAnimation(.snappy) {
                        model.applyTransfer(transfer)
                    }
                }
                .padding(.top, 8)
            }

            EntryLiveSlot {
                if let remaining = model.loanRemaining,
                   remaining != model.amount {
                    payOffButton(remaining)
                }
            }
        }
    }
}

private extension EntrySheet {
    func payOffButton(_ remaining: Int) -> some View {
        ChipButton(
            "残り \(AmountText.text(remaining)) をまとめて返す",
            systemImage: "checkmark.seal",
            size: .large
        ) {
            withAnimation(.snappy) {
                model.payOffLoan()
            }
        }
        .transition(.opacity)
    }
}
