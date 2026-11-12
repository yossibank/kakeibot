import DesignSystem
import SwiftUI

struct EntryVoiceButton: View {
    @State private var isGlowing = false

    let showsTitle: Bool
    let glows: Bool
    let onGlowed: () -> Void
    let action: () -> Void

    var body: some View {
        ChipButton(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "mic")
                    .foregroundStyle(Palette.accent)

                if showsTitle {
                    Text("声")
                        .foregroundStyle(Palette.accentStrong)
                }
            }
            .lineLimit(1)
        }
        .overlay {
            if glows {
                Capsule()
                    .stroke(Palette.accent, lineWidth: 2)
                    .scaleEffect(isGlowing ? Self.glowScale : 1)
                    .opacity(isGlowing ? 0 : 0.9)
                    .allowsHitTesting(false)
            }
        }
        .task(id: glows) {
            await glow()
        }
    }
}

private extension EntryVoiceButton {
    static let glowScale: CGFloat = 1.4
    static let glowDelay: Duration = .milliseconds(600)
    static let glowDuration = 1.2

    func glow() async {
        guard glows else {
            return
        }

        try? await Task.sleep(for: Self.glowDelay)

        guard !Task.isCancelled else {
            return
        }

        withAnimation(.easeOut(duration: Self.glowDuration)) {
            isGlowing = true
        }

        try? await Task.sleep(for: .seconds(Self.glowDuration))

        guard !Task.isCancelled else {
            return
        }

        onGlowed()
    }
}

#Preview {
    HStack(spacing: 8) {
        EntryVoiceButton(showsTitle: true, glows: true, onGlowed: {}) {}
        EntryVoiceButton(showsTitle: false, glows: false, onGlowed: {}) {}
    }
    .padding()
    .background(Palette.panel)
}
