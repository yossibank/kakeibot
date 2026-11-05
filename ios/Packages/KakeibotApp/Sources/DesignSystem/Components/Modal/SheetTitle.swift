import SwiftUI

public struct SheetTitle: View {
    let text: String
    let wraps: Bool

    public init(
        _ text: String,
        wraps: Bool = true
    ) {
        self.text = text
        self.wraps = wraps
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            label(text, tracking: Self.tracking)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            label(fallback, tracking: Self.wrappedTracking)
                .lineLimit(wraps ? 2 : 1)
                .minimumScaleFactor(Self.wrappedScale)
        }
    }
}

private extension SheetTitle {
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

private extension SheetTitle {
    static let tracking: CGFloat = 4
    static let wrappedTracking: CGFloat = 2
    static let wrappedScale: CGFloat = 0.6

    var fallback: String {
        wraps ? text.replacingOccurrences(of: "を", with: "を\n") : text
    }
}
