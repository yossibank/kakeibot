import DesignSystem
import SwiftUI

struct EntryVoiceCountdown: View {
    let start: Date?
    let duration: TimeInterval
    let isSpent: Bool

    var body: some View {
        TimelineView(.animation(paused: start == nil)) { context in
            Capsule()
                .fill(Palette.outline)
                .overlay(alignment: .leading) {
                    Palette.accent
                        .scaleEffect(x: left(at: context.date), anchor: .leading)
                }
                .clipShape(.capsule)
                .frame(height: Self.height)
        }
    }
}

private extension EntryVoiceCountdown {
    static let height: CGFloat = 4

    func left(at date: Date) -> Double {
        guard !isSpent else {
            return 0
        }

        guard let start, duration > 0 else {
            return 1
        }

        let passed = date.timeIntervalSince(start) / duration
        return min(max(1 - passed, 0), 1)
    }
}
