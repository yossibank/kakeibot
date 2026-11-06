import Core
import DesignSystem
import SwiftUI

struct EntryCategoryCell: View {
    @State private var isPressing = false
    @State private var frame = FrameHolder()

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
        .scaleEffect(scale)
        .animation(.snappy(duration: 0.2), value: isPressing)
        .animation(.snappy(duration: 0.25), value: isSelected)
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(EntrySheet.coordinateSpace))
        } action: { rect in
            frame.rect = rect
        }
        .onTapGesture(perform: onSelect)
        .onLongPressGesture(minimumDuration: Self.menuPressDuration) {
            onMenu(frame.rect)
        } onPressingChanged: { isPressing in
            self.isPressing = isPressing
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
    final class FrameHolder {
        var rect: CGRect = .zero
    }

    static let menuPressDuration = 0.4
    static let selectedScale: CGFloat = 1.05
    static let pressedScale: CGFloat = 0.93

    var scale: CGFloat {
        if isPressing {
            return Self.pressedScale
        }

        return isSelected ? Self.selectedScale : 1
    }
}
