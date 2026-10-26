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
            VStack(spacing: 12) {
                Text(title(role))
                    .textFont(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                IconImage(icon, size: 24)
                    .foregroundStyle(Palette.accent)

                Text(wallet?.name ?? "選ぶ")
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)

                if let current {
                    VStack(spacing: 2) {
                        balanceLine(current)

                        balanceLine(after ?? current)
                            .opacity(after == nil ? 0 : 1)

                        if isOver {
                            Text(Self.overNote)
                                .textFont(.caption2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                    }
                    .foregroundStyle(balanceColor)
                    .animation(.snappy, value: after)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 120)
            .card(cornerRadius: 20)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func balanceLine(_ line: EntryModel.BalanceLine) -> some View {
        HStack(spacing: 4) {
            Text(line.title)

            Spacer(minLength: 4)

            Text(AmountText.text(line.amount))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .textFont(.caption2)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private extension EntryTransferPanel {
    static let overNote = "残高を超えています"

    func title(_ role: EntryWalletSheet.Role) -> String {
        switch role {
        case .source: model.walletTitle
        case .destination: EntryModel.destinationTitle
        }
    }
}
