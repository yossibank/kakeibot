import Core
import DesignSystem
import SwiftUI

struct EntryWalletSheet: View {
    @Bindable var model: EntryModel

    @State private var isAdding = false
    @State private var added: Wallet?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    let role: Role

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(title)
                        .textFont(.headline)
                        .foregroundStyle(Palette.accentStrong)

                    Spacer()

                    RingButton(systemImage: "plus") {
                        isAdding = true
                    }
                }

                ForEach(model.walletSections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.kind.title)
                            .textFont(.caption)
                            .tracking(2)
                            .foregroundStyle(Palette.subtext)

                        ForEach(section.wallets) { wallet in
                            walletRow(wallet)
                        }
                    }
                }

                if showsBills {
                    billSection
                        .transition(Self.billTransition)
                }
            }
        }
        .sheet(isPresented: $isAdding, onDismiss: chooseAdded) {
            WalletEditSheet(model: model.newWalletModel()) { wallet in
                added = wallet
            }
        }
    }
}

extension EntryWalletSheet {
    enum Role: Hashable {
        case source
        case destination
    }
}

private extension EntryWalletSheet {
    func walletRow(_ wallet: Wallet) -> some View {
        let isSelected = selectedId == wallet.id
        let isTaken = takenId == wallet.id
        let nameColor = isSelected ? Palette.accentStrong : Palette.text
        let iconColor = isSelected ? Palette.accent : Palette.subtext

        return Button {
            withAnimation(.snappy) {
                select(wallet)
            }

            if !showsBills {
                dismiss()
            }
        } label: {
            HStack(spacing: 12) {
                IconImage(model.icon(for: wallet), size: 18)
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .foregroundStyle(nameColor)

                    if let balance = model.balanceText(of: wallet) {
                        Text(balance)
                            .textFont(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.accent)
                } else if isTaken {
                    Text("\(takenTitle)に選択中")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(
                isSelected ? Palette.accent.opacity(.subtle) : Color.clear,
                in: .rect(cornerRadius: corner.radius(16))
            )
            .overlay {
                RoundedRectangle(cornerRadius: corner.radius(16))
                    .stroke(
                        isSelected ? Palette.accent : Palette.line,
                        lineWidth: 1
                    )
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(isTaken)
        .opacity(isTaken ? 0.45 : 1)
    }
}

private extension EntryWalletSheet {
    var billSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("請求")
                .textFont(.caption)
                .tracking(2)
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 10) {
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
        .sensoryFeedback(.selection, trigger: model.billMonth)
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

            Task {
                try? await Task.sleep(for: Self.closeDelay)
                dismiss()
            }
        } label: {
            VStack(spacing: 6) {
                FlipDate(choice.date, isSelected: isSelected)

                Text(choice.title)
                    .textFont(.caption2)
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
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

private extension EntryWalletSheet {
    static let closeDelay = Duration.milliseconds(300)

    static var billTransition: AnyTransition {
        .opacity.combined(with: .move(edge: .bottom))
    }

    var showsBills: Bool {
        role == .source && !model.billChoices.isEmpty
    }

    var billNote: String? {
        let choices = model.billChoices
        let chosen = choices.first { $0.date == model.selectedBillDate }

        guard let chosen else {
            return nil
        }

        let day = "\(chosen.date.month)/\(chosen.date.day)"

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

    var takenId: Wallet.ID? {
        guard model.type == .transfer else {
            return nil
        }

        switch role {
        case .source: return model.toWalletId
        case .destination: return model.walletId
        }
    }

    var takenTitle: String {
        switch role {
        case .source: EntryModel.destinationTitle
        case .destination: model.walletTitle
        }
    }

    var selectedId: Wallet.ID? {
        switch role {
        case .source: model.walletId
        case .destination: model.toWalletId
        }
    }

    func chooseAdded() {
        guard let added else {
            return
        }

        self.added = nil

        Task {
            await model.reloadWallets()
            select(added)
            dismiss()
        }
    }

    func select(_ wallet: Wallet) {
        switch role {
        case .source:
            model.walletId = wallet.id
        case .destination:
            model.toWalletId = wallet.id
        }
    }
}
