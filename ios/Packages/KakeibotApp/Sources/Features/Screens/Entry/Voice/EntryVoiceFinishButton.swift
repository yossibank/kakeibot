import DesignSystem
import SwiftUI

struct EntryVoiceFinishButton: View {
    let start: Date?
    let duration: TimeInterval
    let isSpent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            TimelineView(.animation(paused: start == nil)) { context in
                Text("話し終えた")
                    .textFont(.subheadline, weight: .bold)
                    .frame(maxWidth: .infinity, minHeight: Self.height)
                    .background(alignment: .leading) {
                        Capsule()
                            .fill(Palette.accentStrong.opacity(.medium))
                            .scaleEffect(x: filled(at: context.date), anchor: .leading)
                    }
                    .clipShape(.capsule)
                    .goldFace()
            }
        }
        .buttonStyle(.plain)
    }
}

private extension EntryVoiceFinishButton {
    static let height: CGFloat = 44

    func filled(at date: Date) -> Double {
        guard !isSpent else {
            return 1
        }

        guard let start, duration > 0 else {
            return 0
        }

        let passed = date.timeIntervalSince(start) / duration
        return min(max(passed, 0), 1)
    }
}
