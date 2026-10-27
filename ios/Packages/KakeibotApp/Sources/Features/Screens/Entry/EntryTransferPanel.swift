import Core
import DesignSystem
import SwiftUI

struct EntryTransferPanel: View {
    let model: EntryModel
    let onPick: (EntryWalletSheet.Role) -> Void

    var body: some View {
        HStack(spacing: 12) {
            card(.source)

            Button {
                withAnimation(.snappy) {
                    model.swapWallets()
                }
            } label: {
                Image(systemName: "arrow.left.arrow.right")
                    .sansFont(.small, weight: .light)
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
        let current = wallet.flatMap(model.currentLine)

        let after = wallet.flatMap { wallet in
            model.afterLine(of: wallet, isSource: role == .source)
        }

        return Button {
            onPick(role)
        } label: {
            VStack(spacing: 6) {
                Text(title(role))
                    .textFont(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                IconImage(icon, size: 20)
                    .foregroundStyle(Palette.accent)

                Text(wallet?.name ?? "選ぶ")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)

                if let current {
                    Grid(horizontalSpacing: 8, verticalSpacing: 4) {
                        balanceLine(current)

                        if let after {
                            balanceLine(after)
                        } else {
                            balanceLine(current)
                                .opacity(0)
                        }
                    }
                    .textFont(.footnote)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(balanceColor)
                    .animation(.snappy, value: after)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .card(cornerRadius: 20)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func balanceLine(_ line: EntryModel.BalanceLine) -> some View {
        GridRow {
            Text(line.title)
                .gridColumnAlignment(.leading)

            Text(AmountText.text(line.amount))
                .monospacedDigit()
                .contentTransition(.numericText())
                .gridColumnAlignment(.trailing)
        }
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
