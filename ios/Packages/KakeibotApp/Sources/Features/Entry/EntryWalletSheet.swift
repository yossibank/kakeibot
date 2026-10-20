import Core
import DesignSystem
import SwiftUI

struct EntryWalletSheet: View {
    @Bindable var model: EntryModel

    @State private var isAdding = false
    @State private var added: Wallet?

    @Environment(\.dismiss) private var dismiss

    let role: Role

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Palette.accentStrong)

                    Spacer()

                    RingButton(systemImage: "plus") {
                        isAdding = true
                    }
                }

                ForEach(model.walletSections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.kind.title)
                            .font(.caption)
                            .tracking(2)
                            .foregroundStyle(Palette.subtext)

                        ForEach(section.wallets) { wallet in
                            walletRow(wallet)
                        }
                    }
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
            select(wallet)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                IconImage(model.icon(for: wallet), size: 18)
                    .foregroundStyle(iconColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text(wallet.name)
                        .foregroundStyle(nameColor)

                    if let balance = model.balance(of: wallet) {
                        Text("残高 \(AmountText.text(balance))")
                            .font(.caption2)
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
                        .font(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(
                isSelected ? Palette.accent.opacity(.subtle) : Color.clear,
                in: .rect(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
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
