import Core
import DesignSystem
import SwiftUI

struct EntryWalletSheet: View {
    @Bindable var model: EntryModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 20) {
                Text("財布")
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

private extension EntryWalletSheet {
    func walletRow(_ wallet: Wallet) -> some View {
        let isSelected = model.walletId == wallet.id

        return Button {
            model.walletId = wallet.id
            dismiss()
        } label: {
            HStack(spacing: 12) {
                IconImage(model.icon(for: wallet), size: 18)
                    .foregroundStyle(isSelected ? Palette.gold : Palette.mist)

                Text(wallet.name)
                    .foregroundStyle(isSelected ? Palette.champagne : Palette.ink)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Palette.gold)
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
                    .stroke(isSelected ? Palette.gold : Palette.line, lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
