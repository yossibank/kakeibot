import SwiftUI

public struct DonutChart<ID: Hashable>: View {
    let slices: [Slice]
    let lineWidth: CGFloat

    public init(
        _ slices: [Slice],
        lineWidth: CGFloat = 18
    ) {
        self.slices = slices
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Palette.line, lineWidth: lineWidth)

            ForEach(segments) { segment in
                Circle()
                    .trim(from: segment.start, to: segment.end)
                    .stroke(segment.color, lineWidth: lineWidth)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(lineWidth / 2)
    }
}

public extension DonutChart {
    struct Slice: Identifiable {
        public let id: ID
        public let value: Int
        public let color: Color

        public init(
            id: ID,
            value: Int,
            color: Color
        ) {
            self.id = id
            self.value = value
            self.color = color
        }
    }
}

private extension DonutChart {
    struct Segment: Identifiable {
        let id: ID
        let start: CGFloat
        let end: CGFloat
        let color: Color
    }

    static var gap: CGFloat {
        0.006
    }

    var segments: [Segment] {
        let total = slices.reduce(0) { $0 + max($1.value, 0) }

        guard total > 0 else {
            return []
        }

        let gap = slices.count > 1 ? Self.gap : 0
        var start: CGFloat = 0

        return slices.map { slice in
            let share = CGFloat(max(slice.value, 0)) / CGFloat(total)
            let end = start + share
            let trimmedEnd = max(start, end - gap)
            defer { start = end }

            return Segment(
                id: slice.id,
                start: start,
                end: trimmedEnd,
                color: slice.color
            )
        }
    }
}
