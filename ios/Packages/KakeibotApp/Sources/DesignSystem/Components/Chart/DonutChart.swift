import SwiftUI

public struct DonutChart<ID: Hashable>: View {
    let slices: [Slice]
    let lineWidth: CGFloat
    let onSelect: ((ID) -> Void)?

    public init(
        _ slices: [Slice],
        lineWidth: CGFloat = 18,
        onSelect: ((ID) -> Void)? = nil
    ) {
        self.slices = slices
        self.lineWidth = lineWidth
        self.onSelect = onSelect
    }

    public var body: some View {
        GeometryReader { proxy in
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
            .contentShape(Circle())
            .onTapGesture { location in
                select(at: location, in: proxy.size)
            }
        }
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

    func select(
        at location: CGPoint,
        in size: CGSize
    ) {
        let radius = min(size.width, size.height) / 2
        let dx = location.x - size.width / 2
        let dy = location.y - size.height / 2
        let distance = (dx * dx + dy * dy).squareRoot()

        guard
            let onSelect,
            distance >= radius - lineWidth * 1.5,
            distance <= radius + lineWidth / 2
        else {
            return
        }

        let angle = atan2(dx, -dy)
        let turn = angle < 0 ? angle + 2 * .pi : angle
        let fraction = turn / (2 * .pi)
        let gap = slices.count > 1 ? Self.gap : 0

        let segment = segments.first { segment in
            fraction >= segment.start && fraction < segment.end + gap
        }

        if let segment {
            onSelect(segment.id)
        }
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
