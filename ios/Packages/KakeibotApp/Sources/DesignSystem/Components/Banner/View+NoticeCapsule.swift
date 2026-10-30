import SwiftUI

public extension View {
    func noticeCapsule(_ tone: NoticeBanner.Tone = .info) -> some View {
        modifier(NoticeCapsule(tone: tone))
    }
}

private struct NoticeCapsule: ViewModifier {
    let tone: NoticeBanner.Tone

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Capsule()
                        .fill(Palette.panel)

                    Capsule()
                        .fill(Self.sheen)
                }
            }
            .overlay {
                Capsule()
                    .strokeBorder(rim, lineWidth: 0.8)
            }
    }
}

private extension NoticeCapsule {
    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.06), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    var rim: LinearGradient {
        LinearGradient(
            colors: [tone.color.opacity(0.8), tone.color.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
