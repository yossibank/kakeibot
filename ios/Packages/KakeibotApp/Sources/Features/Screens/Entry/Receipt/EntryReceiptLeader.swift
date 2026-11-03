import DesignSystem
import SwiftUI

struct EntryReceiptLeader: View {
    var body: some View {
        EntryRuleShape()
            .stroke(
                Palette.hint.opacity(0.8),
                style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.1, 4])
            )
            .frame(minWidth: 8, maxWidth: .infinity)
            .frame(height: 2)
            .alignmentGuide(.firstTextBaseline) { dimensions in
                dimensions[.bottom] + 3
            }
    }
}
