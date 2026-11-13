import Core
import DesignSystem
import SwiftUI

struct EntryTransferPanel: View {
    @Environment(\.themeStyle.corner) private var corner

    let model: EntryModel
    let onPick: (EntryWalletDeck.Role) -> Void

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

                flow
                    .padding(.leading, 8)

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
                        .background(Palette.card, in: .circle)
                        .overlay {
                            Circle()
                                .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                        }
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
            }
            .frame(height: 44)

            card(.destination)
        }
        .sharesTextScale(id: [model.walletId, model.toWalletId])
        .haptic(.selection, trigger: model.toWalletId)
    }
}

private extension EntryTransferPanel {
    static let iconSize: CGFloat = 44

    var flow: some View {
        HStack(spacing: 4) {
            Image(systemName: "arrow.down")
                .sansFont(.micro, weight: .heavy)

            if model.amount > 0 {
                AmountText(model.amount, font: .style(.caption), color: Palette.accentStrong)
                    .lineLimit(1)
                    .contentTransition(.numericText())
            }
        }
        .foregroundStyle(Palette.accent)
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Palette.accent.opacity(.subtle), in: .capsule)
        .animation(.snappy, value: model.amount)
    }

    func card(_ role: EntryWalletDeck.Role) -> some View {
        let id = role == .source ? model.walletId : model.toWalletId
        let wallet = model.wallet(id)
        let icon = wallet.flatMap { model.icon(for: $0) }
        let isOver = role == .source && model.isOverSourceBalance
        let balanceColor = isOver ? Palette.rose : Palette.subtext
        let current = wallet.flatMap(model.currentLine)
        let nameColor = wallet == nil ? Palette.hint : Palette.text
        let iconShape = RoundedRectangle(cornerRadius: corner.radius(12))
        let shape = RoundedRectangle(cornerRadius: corner.radius(20))
        let tint = icon.flatMap { Color(hex: $0.color) } ?? Palette.accent

        let after = wallet.flatMap { wallet in
            model.afterLine(of: wallet, isSource: role == .source)
        }

        let idleAfter = wallet.flatMap { wallet in
            model.idleAfterLine(of: wallet, isSource: role == .source)
        }

        let info = VStack(alignment: .leading, spacing: 4) {
            roleTag(role)

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
                IconImage(icon, size: 22)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Self.iconSize, height: Self.iconSize)
                    .background(tint.opacity(.subtle), in: iconShape)
                    .overlay {
                        iconShape
                            .strokeBorder(tint.opacity(.medium), lineWidth: 1.5)
                    }

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

                Image(systemName: "chevron.right")
                    .sansFont(.micro, weight: .bold)
                    .foregroundStyle(Palette.hint)
            }
            .padding(.leading, 16)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(EntrySlip.cardFill, in: shape)
            .overlay {
                shape
                    .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1)
            }
            .overlay {
                shape
                    .inset(by: 1)
                    .stroke(EntrySlip.shine, lineWidth: 1)
            }
            .shadow(color: Palette.shadow.opacity(.soft), radius: 6, y: 3)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func roleTag(_ role: EntryWalletDeck.Role) -> some View {
        let tag = Text(title(role))
            .textFont(.caption2, weight: .bold)
            .fixedSize()
            .padding(.horizontal, 8)
            .frame(height: 20)

        switch role {
        case .source:
            tag
                .foregroundStyle(Palette.backgroundBottom)
                .background(EntrySlip.gold, in: .capsule)

        case .destination:
            tag
                .foregroundStyle(Palette.accent)
                .overlay {
                    Capsule()
                        .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 1)
                }
        }
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
    func title(_ role: EntryWalletDeck.Role) -> String {
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
