import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    @ViewBuilder
    func itemList(_ row: EntryRowItem) -> some View {
        if !row.items.isEmpty {
            let isOpen = openItemIds.contains(row.id)

            VStack(alignment: .leading, spacing: 8) {
                itemToggle(row, isOpen: isOpen)

                if isOpen {
                    RecordsItemReceipt(items: row.items, amount: row.amount)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .padding(.leading, Self.itemIndent)
            .padding(.bottom, 12)
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
}

private extension RecordsView {
    func itemToggle(
        _ row: EntryRowItem,
        isOpen: Bool
    ) -> some View {
        Button {
            toggleItems(row.id)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "receipt")
                    .foregroundStyle(Palette.accent)

                Text("品目 \(row.items.count) 件")
                    .foregroundStyle(Palette.subtext)

                Image(systemName: "chevron.down")
                    .foregroundStyle(Palette.hint)
                    .rotationEffect(.degrees(isOpen ? 180 : 0))
            }
            .textFont(.caption)
            .contentShape(.rect)
            .tapArea(Self.itemToggleTapOutsets)
        }
        .buttonStyle(.plain)
    }
}

private extension RecordsView {
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
