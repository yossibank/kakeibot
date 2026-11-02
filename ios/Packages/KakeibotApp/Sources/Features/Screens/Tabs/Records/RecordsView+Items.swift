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
                    RecordsItemReceipt(
                        taxIncluded: row.taxIncluded,
                        onClose: {
                            toggleItems(row.id)
                        },
                        items: row.items,
                        amount: row.amount
                    )
                    .transition(.receiptEmerge)
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
        withAnimation(.smooth(duration: 0.36)) {
            if openItemIds.contains(id) {
                openItemIds.remove(id)
            } else {
                openItemIds.insert(id)
            }
        }
    }
}

private struct ReceiptEmerge: ViewModifier {
    let progress: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(
                x: Self.start.width + (1 - Self.start.width) * progress,
                y: Self.start.height + (1 - Self.start.height) * progress,
                anchor: .topLeading
            )
    }
}

private extension ReceiptEmerge {
    static let start = CGSize(width: 0.35, height: 0)
}

private extension AnyTransition {
    static var receiptEmerge: AnyTransition {
        AnyTransition
            .modifier(
                active: ReceiptEmerge(progress: 0),
                identity: ReceiptEmerge(progress: 1)
            )
            .combined(
                with: .asymmetric(
                    insertion: .opacity.animation(.easeOut(duration: 0.18)),
                    removal: .opacity.animation(.easeIn(duration: 0.3))
                )
            )
    }
}
