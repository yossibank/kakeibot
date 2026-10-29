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

            if let remaining = model.loanRemaining,
               remaining != model.amount {
                payOffButton(remaining)
            }
        }
    }
}

private extension EntrySheet {
    func payOffButton(_ remaining: Int) -> some View {
        Button {
            withAnimation(.snappy) {
                model.payOffLoan()
            }
        } label: {
            Label(
                "残り \(AmountText.text(remaining)) をまとめて返す",
                systemImage: "checkmark.seal"
            )
            .textFont(.footnote)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .frame(minHeight: 40)
            .overlay {
                Capsule()
                    .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .transition(.opacity)
    }
}
