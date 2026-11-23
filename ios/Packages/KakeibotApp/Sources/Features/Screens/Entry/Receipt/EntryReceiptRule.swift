import DesignSystem
import SwiftUI

struct EntryReceiptRule: View {
    let style: Style

    var body: some View {
        switch style {
        case .dashed:
            EntryRuleShape()
                .stroke(
                    Palette.subtext.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                .frame(height: 1)

        case .double:
            VStack(spacing: 2) {
                Rectangle()
                    .fill(Palette.text.opacity(0.6))
                    .frame(height: 1)

                Rectangle()
                    .fill(Palette.text.opacity(0.6))
                    .frame(height: 1)
            }
        }
    }
}

extension EntryReceiptRule {
    enum Style {
        case dashed
        case double
    }
}
