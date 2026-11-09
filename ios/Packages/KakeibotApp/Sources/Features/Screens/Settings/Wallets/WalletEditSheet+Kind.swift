import Core
import DesignSystem
import SwiftUI

extension WalletEditSheet {
    enum KindGroup: CaseIterable {
        case onHand
        case debt
        case investment

        var title: String {
            switch self {
            case .onHand: "手持ち"
            case .debt: "後で払う・返す"
            case .investment: "値動きがある"
            }
        }

        var note: String {
            switch self {
            case .onHand: "使えるお金"
            case .debt: "負債になる"
            case .investment: "評価額で合わせる"
            }
        }

        var kinds: [Wallet.Kind] {
            Wallet.Kind.allCases.filter { Self($0) == self }
        }

        init(_ kind: Wallet.Kind) {
            self = switch kind.role {
            case .onHand: .onHand
            case .card, .loan: .debt
            case .investment: .investment
            }
        }
    }

    static let kindColumns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: 8
        ),
        count: 3
    )

    var kindChooser: some View {
        SettingsFormSection("種類", value: model.kind.title) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(KindGroup.allCases, id: \.self) { group in
                    kindGroup(group)
                }
            }
        }
    }

    func kindGroup(_ group: KindGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(group.title)
                    .textFont(.caption, weight: .bold)
                    .foregroundStyle(Palette.text)

                Text(group.note)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.hint)
            }
            .lineLimit(1)
            .padding(.leading, 8)

            LazyVGrid(columns: Self.kindColumns, spacing: 8) {
                ForEach(group.kinds, id: \.self) { kind in
                    kindButton(kind)
                }
            }
        }
    }

    func kindButton(_ kind: Wallet.Kind) -> some View {
        let isSelected = model.kind == kind
        let textColor = isSelected ? Palette.accentStrong : Palette.subtext
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)

        return Button {
            model.kind = kind
        } label: {
            Text(kind.title)
                .textFont(.footnote)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(fill, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(stroke, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .haptic(.selection, trigger: isSelected)
    }
}
