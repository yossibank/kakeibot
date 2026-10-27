import Core
import DesignSystem
import SwiftUI

struct EntryRecentTransfers: View {
    let model: EntryModel
    let transfers: [Entry]
    let onUse: (Entry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近の振替")
                .textFont(.caption2)
                .tracking(2)
                .foregroundStyle(Palette.subtext)
                .padding(.horizontal, 4)

            ForEach(transfers) { transfer in
                row(transfer)
            }
        }
        .sharesTextScale(id: names)
    }
}

private extension EntryRecentTransfers {
    var names: [String] {
        transfers.flatMap { transfer in
            [transfer.walletId, transfer.toWalletId].map { id in
                model.wallet(id)?.name ?? ""
            }
        }
    }

    func row(_ transfer: Entry) -> some View {
        let fee = model.fee(of: transfer)

        return Button {
            onUse(transfer)
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    EntryRouteChip(
                        model.wallet(transfer.walletId)?.name ?? "",
                        isDestination: false
                    )

                    Image(systemName: "arrow.right")
                        .sansFont(.micro, weight: .semibold)
                        .foregroundStyle(Palette.subtext)

                    EntryRouteChip(
                        model.wallet(transfer.toWalletId)?.name ?? "",
                        isDestination: true
                    )
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(AmountText.text(transfer.amount))
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .fixedSize()

                    if fee > 0 {
                        Text("＋手数料 \(AmountText.text(fee))")
                            .textFont(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .fixedSize()
                    }
                }
                .layoutPriority(1)

                Image(systemName: "chevron.right")
                    .sansFont(.micro, weight: .semibold)
                    .foregroundStyle(Palette.subtext)
            }
            .textFont(.footnote)
            .padding(.horizontal, 4)
            .frame(minHeight: 36)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}
