import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct EntryWalletPanel: View {
    @Environment(\.themeStyle.corner) var corner

    @State private var layout = Layout()

    let model: EntryModel
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
                    isSelected: shown.isEditing
                ) {
                    withAnimation(.snappy) {
                        model.state.toggleWalletEditing()
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

                    if shown.isBillShown {
                        billSection
                            .transition(.opacity)
                    }
                }
                .padding(.top, 4)
                .padding(.bottom, 1)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollPosition($layout.scrollPosition)
        }
        .haptic(.selection, trigger: model.state.payment.billMonth)
        .onChange(of: model.state.payment.walletId, initial: true) {
            model.state.openBills(model.state.payment.billMonth != nil)
        }
        .onChange(of: billTrigger, initial: true) { old, new in
            showBills(from: old, to: new)
        }
    }
}

extension EntryWalletPanel {
    typealias Role = EntryModel.WalletRole
}

private extension EntryWalletPanel {
    struct Layout {
        var scrollPosition = ScrollPosition()
    }

    struct BillTrigger: Equatable {
        let walletId: Wallet.ID?
        let showsBills: Bool
    }
}

extension EntryWalletPanel {
    var shown: EntryModel.WalletDeck {
        model.state.screen.wallets
    }
}

private extension EntryWalletPanel {
    var editBadge: some View {
        Image(systemName: "pencil")
            .sansFont(.micro, weight: .heavy)
            .foregroundStyle(Palette.backgroundBottom)
            .frame(width: Self.badgeSize, height: Self.badgeSize)
            .background(Palette.accent, in: .circle)
            .offset(x: -4, y: -4)
    }

    func tile(_ wallet: Wallet) -> some View {
        let isSelected = selectedId == wallet.id
        let isLocked = takenId == wallet.id && !shown.isEditing
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Palette.panel.opacity(.strong)
        let ring = isSelected ? Palette.accent : Palette.line

        return Button {
            guard !shown.isEditing else {
                onEdit(wallet)
                return
            }

            withAnimation(.snappy) {
                onChoose(wallet)
            }
        } label: {
            HStack(spacing: 8) {
                IconImage(model.output.icon(for: wallet), size: 16)
                    .foregroundStyle(isSelected ? Palette.accent : Palette.subtext)

                tileText(wallet, isSelected: isSelected)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(ring, lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                if shown.isEditing {
                    editBadge
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .disabled(isLocked)
        .opacity(isLocked ? 0.45 : 1)
    }

    func tileText(
        _ wallet: Wallet,
        isSelected: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Text(wallet.name)
                    .textFont(.subheadline, weight: .medium)
                    .foregroundStyle(isSelected ? Palette.accentStrong : Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if model.output.isShared(wallet) {
                    SharedMark()
                }
            }

            if let balance = model.output.balanceText(of: wallet) {
                Text(balance)
                    .textFont(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

private extension EntryWalletPanel {
    static let badgeSize: CGFloat = 20

    static let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var wallets: [Wallet] {
        model.output.walletSections.flatMap(\.wallets)
    }

    var showsBills: Bool {
        role == .source && !model.output.billChoices.isEmpty && !shown.isEditing
    }

    var billTrigger: BillTrigger {
        BillTrigger(walletId: model.state.payment.walletId, showsBills: showsBills)
    }

    var editTitle: String {
        shown.isEditing ? "完了" : "編集"
    }

    var editImage: String {
        shown.isEditing ? "checkmark" : "pencil"
    }

    var title: String {
        switch role {
        case .source: model.output.walletTitle
        case .destination: EntryModel.destinationTitle
        }
    }

    var selectedId: Wallet.ID? {
        switch role {
        case .source: model.state.payment.walletId
        case .destination: model.state.payment.toWalletId
        }
    }

    var takenId: Wallet.ID? {
        guard model.state.type == .transfer else {
            return nil
        }

        switch role {
        case .source: return model.state.payment.toWalletId
        case .destination: return model.state.payment.walletId
        }
    }

    func showBills(
        from old: BillTrigger,
        to new: BillTrigger
    ) {
        guard old != new else {
            model.state.showBills(new.showsBills)
            return
        }

        let isChosen = old.walletId != new.walletId

        guard old.showsBills != new.showsBills else {
            if isChosen, shown.isBillShown {
                scrollToBills()
            }

            return
        }

        withAnimation(.snappy) {
            model.state.showBills(new.showsBills)
        } completion: {
            guard isChosen, shown.isBillShown else {
                return
            }

            scrollToBills()
        }
    }

    func scrollToBills() {
        withAnimation(.snappy) {
            layout.scrollPosition.scrollTo(edge: .bottom)
        }
    }
}
