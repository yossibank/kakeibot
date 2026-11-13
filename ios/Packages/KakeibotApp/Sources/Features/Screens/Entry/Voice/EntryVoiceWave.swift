import DesignSystem
import SwiftUI

struct EntryVoiceWave: View {
    let flow: EntryVoiceFlow
    let reach: Int
    let height: CGFloat

    var body: some View {
        let levels = flow.levels

        ZStack {
            Capsule()
                .fill(Palette.accent.opacity(.soft))
                .frame(height: 1)

            HStack(spacing: Self.gap) {
                ForEach(-reach...reach, id: \.self) { offset in
                    let distance = abs(offset)
                    let level = level(levels, at: distance)

                    Capsule()
                        .fill(Self.fill)
                        .frame(width: Self.barWidth, height: barHeight(level))
                        .glow(Palette.accent.opacity(level), radius: Self.glowRadius * level)
                }
            }
        }
        .frame(height: height)
        .animation(.spring(duration: Self.step, bounce: 0.35), value: levels)
    }
}

private extension EntryVoiceWave {
    static let barWidth: CGFloat = 4
    static let gap: CGFloat = 3
    static let glowRadius: CGFloat = 6
    static let step = 0.15
    static let taper = 0.6

    static var fill: LinearGradient {
        LinearGradient(
            colors: [Palette.accent, Palette.accentStrong],
            startPoint: .bottom,
            endPoint: .top
        )
    }

    func level(
        _ levels: [Double],
        at distance: Int
    ) -> Double {
        let level = distance < levels.count ? levels[distance] : 0
        let fade = 1 - Self.taper * Double(distance) / Double(max(reach, 1))
        return level * fade
    }

    func barHeight(_ level: Double) -> CGFloat {
        Self.barWidth + (height - Self.barWidth) * level
    }
}
