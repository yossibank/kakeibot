import Core
import DesignSystem
import SwiftUI

struct EntryTransferPanel: View {
    @Environment(\.themeStyle.corner) private var corner

    let model: EntryModel
    let onPick: (EntryWalletSheet.Role) -> Void

    var body: some View {
        VStack(spacing: 0) {
            card(.source)

            HStack(spacing: 0) {
                EntryTransferLink()
                    .stroke(
                        Palette.accent.opacity(.medium),
                        style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [1, 4])
                    )
                    .frame(width: Self.iconSize)
                    .padding(.leading, 16)

                Spacer(minLength: 0)

                Button {
                    withAnimation(.snappy) {
                        model.swapWallets()
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .textFont(.caption, weight: .semibold)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 32, height: 32)
                        .background(Palette.panel, in: .circle)
                        .overlay {
                            Circle()
                                .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                        }
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
            }
            .frame(height: 48)

            card(.destination)
        }
        .sharesTextScale(id: [model.walletId, model.toWalletId])
        .haptic(.selection, trigger: model.toWalletId)
    }
}

private extension EntryTransferPanel {
    static let iconSize: CGFloat = 40

    func card(_ role: EntryWalletSheet.Role) -> some View {
        let id = role == .source ? model.walletId : model.toWalletId
        let wallet = model.wallet(id)
        let icon = wallet.flatMap { model.icon(for: $0) }
        let isOver = role == .source && model.isOverSourceBalance
        let balanceColor = isOver ? Palette.rose : Palette.subtext
        let current = wallet.flatMap(model.currentLine)
        let nameColor = wallet == nil ? Palette.hint : Palette.text
        let iconShape = RoundedRectangle(cornerRadius: corner.radius(12))

        let after = wallet.flatMap { wallet in
            model.afterLine(of: wallet, isSource: role == .source)
        }

        let idleAfter = wallet.flatMap { wallet in
            model.idleAfterLine(of: wallet, isSource: role == .source)
        }

        let info = VStack(alignment: .leading, spacing: 2) {
            Text(title(role))
                .textFont(.caption2, weight: .bold)
                .tracking(2)
                .foregroundStyle(Palette.accent)
                .fixedSize()

            Text(wallet?.name ?? "選ぶ")
                .textFont(.subheadline, weight: .bold)
                .foregroundStyle(nameColor)
                .lineLimit(2)
                .sharedTextScale()
        }

        let balances = Grid(alignment: .trailing, horizontalSpacing: 8, verticalSpacing: 2) {
            if let current {
                balanceLine(current)
            }

            if let after {
                balanceLine(after)
            } else if let idleAfter {
                balanceLine(idleAfter)
                    .foregroundStyle(Palette.hint)
            }
        }
        .textFont(.caption)
        .lineLimit(1)
        .foregroundStyle(balanceColor)
        .fixedSize()
        .animation(.snappy, value: after)

        return Button {
            onPick(role)
        } label: {
            HStack(spacing: 12) {
                IconImage(icon, size: 20)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Self.iconSize, height: Self.iconSize)
                    .background(Palette.accent.opacity(.subtle), in: iconShape)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        info
                            .fixedSize()

                        Spacer(minLength: 8)

                        balances
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        info

                        balances
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(cornerRadius: 20)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func balanceLine(_ line: EntryModel.BalanceLine) -> some View {
        GridRow {
            Text(line.title)

            AmountText(line.amount, font: .style(.footnote))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())
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

private struct EntryTransferLink: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        }
    }
}
