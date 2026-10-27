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
    }
}

private extension EntryRecentTransfers {
    func row(_ transfer: Entry) -> some View {
        let fee = model.fee(of: transfer)

        return Button {
            onUse(transfer)
        } label: {
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    name(model.wallet(transfer.walletId)?.name ?? "")

                    Text("→")

                    name(model.wallet(transfer.toWalletId)?.name ?? "")
                }
                .foregroundStyle(Palette.text)
                .lineLimit(1)

                Spacer(minLength: 8)

                if fee > 0 {
                    Text("＋手数料 \(AmountText.text(fee))")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                        .lineLimit(1)
                }

                Text(AmountText.text(transfer.amount))
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)

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

    func name(_ text: String) -> some View {
        ViewThatFits(in: .horizontal) {
            ForEach(shortened(text), id: \.self) { candidate in
                Text(candidate)
            }
        }
    }
}

private extension EntryRecentTransfers {
    func shortened(_ text: String) -> [String] {
        let cuts = (1..<max(text.count, 1)).reversed().map { count in
            let head = text.prefix(count).trimmingCharacters(in: .whitespaces)
            return "\(head)…"
        }

        var seen = Set<String>()
        return ([text] + cuts).filter { seen.insert($0).inserted }
    }
}
