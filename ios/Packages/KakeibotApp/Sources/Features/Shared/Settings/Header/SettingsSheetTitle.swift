import DesignSystem
import SwiftUI

struct SettingsSheetTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            label(text, tracking: Self.tracking)
                .lineLimit(1)

            label(wrapped, tracking: Self.wrappedTracking)
                .lineLimit(2)
                .minimumScaleFactor(Self.wrappedScale)
        }
    }
}

private extension SettingsSheetTitle {
    static let tracking: CGFloat = 4
    static let wrappedTracking: CGFloat = 2
    static let wrappedScale: CGFloat = 0.8

    var wrapped: String {
        text.replacingOccurrences(of: "を", with: "を\n")
    }

    func label(
        _ text: String,
        tracking: CGFloat
    ) -> some View {
        Text(text)
            .displayFont(.body)
            .tracking(tracking)
            .multilineTextAlignment(.center)
            .foregroundStyle(Palette.accent)
    }
}
