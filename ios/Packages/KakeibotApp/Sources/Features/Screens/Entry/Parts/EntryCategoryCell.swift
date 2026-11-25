import Core
import DesignSystem
import SwiftUI

struct EntryCategoryCell: View {
    @State private var layout = Layout()

    let category: EntryCategory
    let icon: Icon?
    let isSelected: Bool
    let onSelect: () -> Void
    let onMenu: (CGRect) -> Void

    var body: some View {
        EntryCategoryFace(
            category: category,
            icon: icon,
            isLit: isSelected,
            isLifted: false
        )
        .glow(isSelected ? Palette.glow.opacity(.muted) : Color.clear, radius: 8)
        .scaleEffect(layout.scale)
        .animation(.snappy(duration: 0.2), value: layout.scale)
        .animation(.snappy(duration: 0.25), value: isSelected)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(EntrySheet.coordinateSpace))
        } action: { rect in
            layout.frame = rect
        }
        .onTapGesture(perform: onSelect)
        .onLongPressGesture(minimumDuration: Self.menuPressDuration) {
            onMenu(layout.frame)
        } onPressingChanged: { isPressing in
            layout.scale = isPressing ? Self.pressedScale : 1
        }
    }
}

extension EntryCategoryCell: Equatable {
    nonisolated static func == (
        lhs: EntryCategoryCell,
        rhs: EntryCategoryCell
    ) -> Bool {
        lhs.category == rhs.category
            && lhs.icon == rhs.icon
            && lhs.isSelected == rhs.isSelected
    }
}

private extension EntryCategoryCell {
    struct Layout {
        var frame: CGRect = .zero
        var scale: CGFloat = 1
    }

    static let menuPressDuration = 0.4
    static let pressedScale: CGFloat = 0.93
}
