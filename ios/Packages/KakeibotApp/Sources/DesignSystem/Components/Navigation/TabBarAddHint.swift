import SwiftUI

struct TabBarAddHint<S: Shape>: View {
    let shape: S

    var body: some View {
        TimelineView(.animation) { context in
            let seconds = context.date.timeIntervalSinceReferenceDate
            let turn = seconds.truncatingRemainder(dividingBy: Self.period) / Self.period
            let start = turn
            let end = turn + Self.length

            ZStack {
                shape
                    .trim(from: start, to: min(end, 1))
                    .stroke(Palette.accentStrong, style: Self.line)

                if end > 1 {
                    shape
                        .trim(from: 0, to: end - 1)
                        .stroke(Palette.accentStrong, style: Self.line)
                }
            }
            .glow(Palette.accent, radius: 6)
            .padding(1.2)
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }
}

private extension TabBarAddHint {
    static var period: Double {
        2.4
    }

    static var length: CGFloat {
        0.22
    }

    static var line: StrokeStyle {
        StrokeStyle(lineWidth: 2.4, lineCap: .round)
    }
}
