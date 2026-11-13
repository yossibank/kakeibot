import Core
import DesignSystem
import Store
import SwiftUI

struct EntryWalletDeck: View {
    @Bindable var model: EntryModel

    @Environment(\.themeStyle.corner) private var corner

    let role: EntryWalletSheet.Role
    let onChoose: (Wallet) -> Void
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)

                Spacer()

                ChipButton("編集", systemImage: "pencil", action: onEdit)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LazyVGrid(columns: Self.columns, spacing: 8) {
                        ForEach(wallets) { wallet in
                            tile(wallet)
                        }
                    }

                    if showsBills {
                        billSection
                            .transition(.opacity)
                    }
                }
                .padding(.vertical, 1)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .animation(.snappy, value: showsBills)
        .haptic(.selection, trigger: model.billMonth)
    }
}

private extension EntryWalletDeck {
    var billSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("請求")

            HStack(spacing: 8) {
                ForEach(model.billChoices) { choice in
                    billButton(choice)
                }
            }
        }
    }

    func tile(_ wallet: Wallet) -> some View {
        let isSelected = selectedId == wallet.id
        let isTaken = takenId == wallet.id
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Palette.panel.opacity(.strong)
        let ring = isSelected ? Palette.accent : Palette.line

        return Button {
            withAnimation(.snappy) {
                onChoose(wallet)
            }
        } label: {
            HStack(spacing: 8) {
                IconImage(model.icon(for: wallet), size: 16)
                    .foregroundStyle(isSelected ? Palette.accent : Palette.subtext)

                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .textFont(.subheadline, weight: .medium)
                        .foregroundStyle(isSelected ? Palette.accentStrong : Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    if let balance = model.balanceText(of: wallet) {
                        Text(balance)
                            .textFont(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(ring, lineWidth: 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(isTaken)
        .opacity(isTaken ? 0.45 : 1)
    }

    func billButton(_ choice: EntryModel.BillChoice) -> some View {
        let isSelected = model.selectedBillDate == choice.date
        let titleColor = isSelected ? Palette.accentStrong : Palette.subtext
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let ring = isSelected ? Palette.accent : Palette.line
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        return Button {
            withAnimation(.snappy) {
                model.selectBill(choice.date)
            }
        } label: {
            VStack(spacing: 4) {
                FlipDate(choice.date, isSelected: isSelected)

                Text(choice.title)
                    .textFont(.caption2)
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(ring, lineWidth: 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
    }
}

private extension EntryWalletDeck {
    static let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var wallets: [Wallet] {
        model.walletSections.flatMap(\.wallets)
    }

    var showsBills: Bool {
        role == .source && !model.billChoices.isEmpty
    }

    var title: String {
        switch role {
        case .source: model.walletTitle
        case .destination: EntryModel.destinationTitle
        }
    }

    var selectedId: Wallet.ID? {
        switch role {
        case .source: model.walletId
        case .destination: model.toWalletId
        }
    }

    var takenId: Wallet.ID? {
        guard model.type == .transfer else {
            return nil
        }

        switch role {
        case .source: return model.toWalletId
        case .destination: return model.walletId
        }
    }
}
