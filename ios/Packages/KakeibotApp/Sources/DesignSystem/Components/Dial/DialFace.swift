import SwiftUI

public struct DialFace: View {
    let isActive: Bool

    public init(isActive: Bool) {
        self.isActive = isActive
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(ringColor, lineWidth: 1)
                .shadow(color: glowColor, radius: 16)

            DialTicks(count: 60, length: 9)
                .stroke(Palette.accent.opacity(.strong), lineWidth: 1)
                .padding(12)

            DialTicks(count: 12, length: 14)
                .stroke(Palette.accentStrong, lineWidth: 1.5)
                .padding(12)
        }
    }
}

private extension DialFace {
    var ringColor: Color {
        isActive ? Palette.accent : Palette.outline
    }

    var glowColor: Color {
        isActive ? Palette.glow.opacity(.muted) : .clear
    }
}

#Preview {
    HStack(spacing: 24) {
        DialFace(isActive: false)
            .frame(width: 160, height: 160)

        DialFace(isActive: true)
            .frame(width: 160, height: 160)
    }
    .padding()
    .background(Palette.background)
}
