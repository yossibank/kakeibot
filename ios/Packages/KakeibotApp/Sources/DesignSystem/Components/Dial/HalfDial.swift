import SwiftUI

public struct HalfDial: View {
    let progress: Double?
    let tint: Color

    public init(
        progress: Double? = nil,
        tint: Color = Palette.gold
    ) {
        self.progress = progress
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            HalfArc(progress: 1)
                .stroke(Palette.line, lineWidth: 2)

            if let progress {
                HalfArc(progress: min(max(progress, 0), 1))
                    .stroke(
                        tint,
                        style: StrokeStyle(lineWidth: 2, lineCap: .round)
                    )
            }

            HalfTicks(count: 30, step: 1, length: 6, inset: 10)
                .stroke(Palette.gold.opacity(0.5), lineWidth: 0.7)

            HalfTicks(count: 30, step: 5, length: 13, inset: 10)
                .stroke(Palette.gold, lineWidth: 1.4)
        }
        .aspectRatio(2, contentMode: .fit)
    }
}

private struct HalfArc: Shape {
    let progress: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height) - 1
        let end = Angle.degrees(180 + 180 * progress)

        return Path { path in
            path.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(180),
                endAngle: end,
                clockwise: false
            )
        }
    }
}

private struct HalfTicks: Shape {
    let count: Int
    let step: Int
    let length: CGFloat
    let inset: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let outer = min(rect.width / 2, rect.height) - inset
        let inner = outer - length

        return Path { path in
            for index in stride(from: 0, through: count, by: step) {
                let angle = Double.pi + Double(index) / Double(count) * .pi
                let start = Self.point(from: center, at: angle, radius: inner)
                let end = Self.point(from: center, at: angle, radius: outer)
                path.move(to: start)
                path.addLine(to: end)
            }
        }
    }
}

private extension HalfTicks {
    static func point(
        from center: CGPoint,
        at angle: Double,
        radius: CGFloat
    ) -> CGPoint {
        let x = center.x + cos(angle) * radius
        let y = center.y + sin(angle) * radius
        return CGPoint(x: x, y: y)
    }
}

#Preview {
    VStack(spacing: 24) {
        HalfDial()
            .frame(width: 290)

        HalfDial(progress: 0.4)
            .frame(width: 290)
    }
    .padding()
    .background(Palette.night)
}
