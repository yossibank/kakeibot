import SwiftUI

public struct SheetTitle: View {
    let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            label(text, tracking: Self.tracking)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            label(wrapped, tracking: Self.wrappedTracking)
                .lineLimit(2)
                .minimumScaleFactor(Self.wrappedScale)
        }
    }
}

private extension SheetTitle {
    static let tracking: CGFloat = 4
    static let wrappedTracking: CGFloat = 2
    static let wrappedScale: CGFloat = 0.6

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
