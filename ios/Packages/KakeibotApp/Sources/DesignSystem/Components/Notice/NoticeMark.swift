import SwiftUI

public struct NoticeMark: View {
    let systemImage: String
    let tone: NoticeBanner.Tone
    let size: CGFloat

    public init(
        systemImage: String,
        tone: NoticeBanner.Tone = .info,
        size: CGFloat = 30
    ) {
        self.systemImage = systemImage
        self.tone = tone
        self.size = size
    }

    public var body: some View {
        Image(systemName: systemImage)
            .sansFont(.caption, weight: .semibold)
            .foregroundStyle(tone.color)
            .frame(width: size, height: size)
            .background(tone.color.opacity(0.12), in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(tone.color.opacity(0.45), lineWidth: 0.6)
            }
    }
}
