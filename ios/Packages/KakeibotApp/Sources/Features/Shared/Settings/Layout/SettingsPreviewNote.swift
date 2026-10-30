import DesignSystem
import SwiftUI

struct SettingsPreviewNote: View {
    let text: String
    let dot: Color?

    init(
        _ text: String,
        dot: Color? = nil
    ) {
        self.text = text
        self.dot = dot
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            if let dot {
                Circle()
                    .fill(dot)
                    .frame(width: 10, height: 10)
                    .alignmentGuide(.firstTextBaseline) { dimensions in
                        dimensions[.bottom]
                    }
            }

            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .textFont(.caption2)
        .tracking(1)
        .foregroundStyle(Palette.subtext)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}
