import SwiftUI

public struct NoticeActionLabel: View {
    let title: String
    let height: CGFloat?

    public init(
        _ title: String,
        height: CGFloat? = 34
    ) {
        self.title = title
        self.height = height
    }

    public var body: some View {
        Text(title)
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, 16)
            .frame(minHeight: height, maxHeight: height ?? .infinity)
            .overlay {
                Capsule()
                    .strokeBorder(Palette.accent.opacity(.medium), lineWidth: 0.8)
            }
            .contentShape(Capsule())
    }
}
