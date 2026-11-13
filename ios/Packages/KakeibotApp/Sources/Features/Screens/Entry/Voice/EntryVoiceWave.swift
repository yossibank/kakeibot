import DesignSystem
import SwiftUI

struct EntryVoiceWave: View {
    let flow: EntryVoiceFlow
    let reach: Int
    let height: CGFloat

    var body: some View {
        let levels = flow.levels

        HStack(spacing: Self.gap) {
            ForEach(-reach...reach, id: \.self) { offset in
                Capsule()
                    .fill(Palette.accent)
                    .frame(
                        width: Self.barWidth,
                        height: barHeight(levels, at: abs(offset))
                    )
            }
        }
        .frame(height: height)
        .animation(.linear(duration: Self.step), value: levels)
    }
}

private extension EntryVoiceWave {
    static let barWidth: CGFloat = 3
    static let gap: CGFloat = 3
    static let step = 0.1
    static let taper = 0.6

    func barHeight(
        _ levels: [Double],
        at distance: Int
    ) -> CGFloat {
        let level = distance < levels.count ? levels[distance] : 0
        let fade = 1 - Self.taper * Double(distance) / Double(max(reach, 1))
        return Self.barWidth + (height - Self.barWidth) * level * fade
    }
}
