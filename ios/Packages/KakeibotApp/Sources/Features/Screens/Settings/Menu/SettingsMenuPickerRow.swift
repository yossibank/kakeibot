import DesignSystem
import SwiftUI

struct SettingsMenuPickerRow<Picker: View>: View {
    let title: String
    let systemImage: String
    let picker: Picker

    init(
        _ title: String,
        systemImage: String,
        picker: Picker
    ) {
        self.title = title
        self.systemImage = systemImage
        self.picker = picker
    }

    var body: some View {
        SettingsMenuPickerRowLayout {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 22)

                Text(title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .fixedSize()
            }

            picker
        }
    }
}

private struct SettingsMenuPickerRowLayout: Layout {
    static let gap: CGFloat = 20
    static let rowHeight: CGFloat = 52
    static let lineSpacing: CGFloat = 8
    static let inset: CGFloat = 12

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let label = subviews[0].sizeThatFits(.unspecified)
        let picker = subviews[1].sizeThatFits(.unspecified)
        let rowWidth = label.width + Self.gap + picker.width
        let width = proposal.width ?? rowWidth

        guard rowWidth > width else {
            return CGSize(width: width, height: max(label.height, picker.height, Self.rowHeight))
        }

        let height = label.height + Self.lineSpacing + picker.height + Self.inset * 2

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let label = subviews[0].sizeThatFits(.unspecified)
        let picker = subviews[1].sizeThatFits(.unspecified)
        let rowWidth = label.width + Self.gap + picker.width

        guard rowWidth > bounds.width else {
            let leading = CGPoint(x: bounds.minX, y: bounds.midY)
            let trailing = CGPoint(x: bounds.maxX, y: bounds.midY)

            subviews[0].place(at: leading, anchor: .leading, proposal: .unspecified)
            subviews[1].place(at: trailing, anchor: .trailing, proposal: .unspecified)

            return
        }

        let top = CGPoint(x: bounds.minX, y: bounds.minY + Self.inset)
        let bottom = CGPoint(x: bounds.maxX, y: bounds.maxY - Self.inset)

        subviews[0].place(at: top, anchor: .topLeading, proposal: .unspecified)
        subviews[1].place(at: bottom, anchor: .bottomTrailing, proposal: .unspecified)
    }
}
