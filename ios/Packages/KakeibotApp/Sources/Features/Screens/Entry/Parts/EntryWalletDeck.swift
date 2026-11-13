import Core
import DesignSystem
import Store
import SwiftUI

struct EntryWalletDeck: View {
    @Bindable var model: EntryModel

    @Environment(\.themeStyle.corner) private var corner

    @State private var isEditing = false

    let role: Role
    let onChoose: (Wallet) -> Void
    let onEdit: (Wallet) -> Void
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)

                Spacer()

                ChipButton("追加", systemImage: "plus", action: onAdd)

                ChipButton(
                    editTitle,
                    systemImage: editImage,
                    isSelected: isEditing
                ) {
                    withAnimation(.snappy) {
                        isEditing.toggle()
                    }
                }
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

extension EntryWalletDeck {
    enum Role: Hashable {
        case source
        case destination
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

            if let billNote {
                Text(billNote)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 4)
            }
        }
    }

    var editBadge: some View {
        Image(systemName: "pencil")
            .sansFont(.micro, weight: .heavy)
            .foregroundStyle(Palette.backgroundBottom)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(Palette.accent, in: .circle)
            .offset(x: 4, y: -8)
    }

    func tile(_ wallet: Wallet) -> some View {
        let isSelected = selectedId == wallet.id
        let isLocked = takenId == wallet.id && !isEditing
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Palette.panel.opacity(.strong)
        let ring = isSelected ? Palette.accent : Palette.line

        return Button {
            guard !isEditing else {
                onEdit(wallet)
                return
            }

            withAnimation(.snappy) {
                onChoose(wallet)
            }
        } label: {
            HStack(spacing: 8) {
                IconImage(model.icon(for: wallet), size: 16)
                    .foregroundStyle(isSelected ? Palette.accent : Palette.subtext)
                    .overlay(alignment: .topTrailing) {
                        if isEditing {
                            editBadge
                                .transition(.scale.combined(with: .opacity))
                        }
                    }

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
        .disabled(isLocked)
        .opacity(isLocked ? 0.45 : 1)
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
    static let badgeSize: CGFloat = 16

    static let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var wallets: [Wallet] {
        model.walletSections.flatMap(\.wallets)
    }

    var showsBills: Bool {
        role == .source && !model.billChoices.isEmpty && !isEditing
    }

    var editTitle: String {
        isEditing ? "完了" : "編集"
    }

    var editImage: String {
        isEditing ? "checkmark" : "pencil"
    }

    var billNote: String? {
        let choices = model.billChoices
        let chosen = choices.first { $0.date == model.selectedBillDate }

        guard let chosen else {
            return nil
        }

        let day = chosen.date.monthDayText

        guard chosen.date == choices.first?.date else {
            return "カード会社の確定が遅れた分として、\(day) の引き落としに入れます"
        }

        let period = chosen.period.map(RecurringText.period) ?? ""

        return "\(period) の利用分として、\(day) に引き落とされます"
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
