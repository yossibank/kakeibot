import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    @ViewBuilder
    func itemList(_ row: EntryRowItem) -> some View {
        if !row.items.isEmpty {
            let isOpen = openItemIds.contains(row.id)

            VStack(alignment: .leading, spacing: 6) {
                Button {
                    toggleItems(row.id)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "receipt")

                        Text("品目 \(row.items.count) 件")

                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(isOpen ? 180 : 0))
                    }
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .contentShape(.rect)
                    .tapArea(Self.itemToggleTapOutsets)
                }
                .buttonStyle(.plain)

                if isOpen {
                    ForEach(row.items) { item in
                        itemLine(item)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.leading, Self.itemIndent)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private extension RecordsView {
    static let itemIndent: CGFloat = 33

    static let itemToggleTapOutsets = EdgeInsets(
        top: 10,
        leading: 8,
        bottom: 10,
        trailing: 8
    )

    func itemLine(_ item: EntryItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(item.name)
                .foregroundStyle(Palette.text)
                .lineLimit(1)

            if item.quantity > 1 {
                Text("×\(item.quantity)")
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            if let rate = item.taxRate {
                Text("\(rate.rawValue)%")
                    .foregroundStyle(Palette.subtext)
            }

            Text(AmountText.text(item.amount))
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
        .textFont(.caption)
    }

    func toggleItems(_ id: Entry.ID) {
        withAnimation(.snappy) {
            if openItemIds.contains(id) {
                openItemIds.remove(id)
            } else {
                openItemIds.insert(id)
            }
        }
    }
}
