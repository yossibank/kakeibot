import Core
import DesignSystem
import SwiftUI

struct EntryWalletSheet: View {
    @Bindable var model: EntryModel

    @Environment(\.dismiss) private var dismiss

    let role: Role

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 20) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Palette.champagne)

                ForEach(model.walletSections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.kind.title)
                            .font(.caption)
                            .tracking(2)
                            .foregroundStyle(Palette.mist)

                        ForEach(section.wallets) { wallet in
                            walletRow(wallet)
                        }
                    }
                }
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
        let nameColor = isSelected ? Palette.champagne : Palette.ink

        return Button {
            select(wallet)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                IconImage(model.icon(for: wallet), size: 18)
                    .foregroundStyle(isSelected ? Palette.gold : Palette.mist)

                Text(wallet.name)
                    .foregroundStyle(nameColor)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.gold)
                } else if isTaken {
                    Text("\(takenTitle)に選択中")
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(
                isSelected ? Palette.gold.opacity(0.1) : Color.clear,
                in: .rect(cornerRadius: 16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Palette.gold : Palette.line,
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

    func select(_ wallet: Wallet) {
        switch role {
        case .source:
            model.walletId = wallet.id
        case .destination:
            model.toWalletId = wallet.id
        }
    }
}

private extension Wallet.Kind {
    var title: String {
        switch self {
        case .cash: "現金"
        case .bank: "銀行"
        case .card: "カード"
        case .emoney: "電子マネー"
        case .point: "ポイント"
        }
    }
}
