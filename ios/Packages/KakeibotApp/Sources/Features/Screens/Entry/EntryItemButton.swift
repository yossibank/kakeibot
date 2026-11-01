import DesignSystem
import SwiftUI

struct EntryItemButton: View {
    let count: Int
    let hasAdjustment: Bool
    let onOpen: () -> Void

    var body: some View {
        RingButton(
            systemImage: "receipt",
            style: count > 0 ? .prominent : .plain,
            action: onOpen
        )
        .overlay(alignment: .topTrailing) {
            if count > 0 {
                badge
                    .clipShape(.capsule)
                    .offset(x: 2, y: -2)
                    .allowsHitTesting(false)
            }
        }
    }
}

private extension EntryItemButton {
    static let badgeSize: CGFloat = 18

    @ViewBuilder
    var badge: some View {
        let text = Text("\(count)")
            .textFont(size: .caption, weight: .bold)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(.horizontal, 4)
            .frame(minWidth: Self.badgeSize, minHeight: Self.badgeSize)

        if hasAdjustment {
            text
                .foregroundStyle(Palette.cardBottom)
                .background(Palette.amber)
        } else {
            text
                .goldFace()
        }
    }
}
