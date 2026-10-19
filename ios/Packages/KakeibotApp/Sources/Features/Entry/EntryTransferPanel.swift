import Core
import DesignSystem
import SwiftUI

struct EntryTransferPanel: View {
    let model: EntryModel
    let onPick: (EntryWalletSheet.Role) -> Void

    var body: some View {
        HStack(spacing: 10) {
            card(.source)

            Button {
                withAnimation(.snappy) {
                    model.swapWallets()
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.sans(.small, weight: .light))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 44, height: 44)
                    .overlay {
                        Circle()
                            .stroke(
                                Palette.accent.opacity(.muted),
                                lineWidth: 1
                            )
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)

            card(.destination)
        }
        .sensoryFeedback(.selection, trigger: model.toWalletId)
    }
}

private extension EntryTransferPanel {
    func card(_ role: EntryWalletSheet.Role) -> some View {
        let id = role == .source ? model.walletId : model.toWalletId
        let wallet = model.wallet(id)
        let icon = wallet.flatMap { model.icon(for: $0) }
        let isOver = role == .source && model.isOverSourceBalance
        let balanceColor = isOver ? Palette.rose : Palette.subtext
        let overOpacity: Double = isOver ? 1 : 0

        return Button {
            onPick(role)
        } label: {
            VStack(spacing: 10) {
                Text(title(role))
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                IconImage(icon, size: 24)
                    .foregroundStyle(Palette.accent)

                Text(wallet?.name ?? "選ぶ")
                    .font(.subheadline)
                    .foregroundStyle(Palette.accentLight)
                    .lineLimit(1)

                if let balance = wallet.flatMap({ model.balance(of: $0) }) {
                    VStack(spacing: 2) {
                        Text("残高 \(AmountText.text(balance))")
                            .font(.caption2)
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Text("残高を超えています")
                            .font(.caption2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .opacity(overOpacity)
                    }
                    .foregroundStyle(balanceColor)
                    .animation(.snappy, value: isOver)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 120)
            .card(cornerRadius: 18)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryTransferPanel {
    func title(_ role: EntryWalletSheet.Role) -> String {
        switch role {
        case .source: model.walletTitle
        case .destination: EntryModel.destinationTitle
        }
    }
}
