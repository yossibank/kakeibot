import SwiftUI

public struct DialTicks: Shape {
    let count: Int
    let length: CGFloat

    public init(
        count: Int,
        length: CGFloat
    ) {
        self.count = count
        self.length = length
    }

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer - length

        return Path { path in
            for index in 0..<count {
                let angle = Double(index) / Double(count) * 2 * .pi
                let start = Self.point(from: center, at: angle, radius: inner)
                let end = Self.point(from: center, at: angle, radius: outer)

                path.move(to: start)
                path.addLine(to: end)
            }
        }
    }
}

private extension DialTicks {
    static func point(
        from center: CGPoint,
        at angle: Double,
        radius: CGFloat
    ) -> CGPoint {
        let x = center.x + sin(angle) * radius
        let y = center.y - cos(angle) * radius

        return CGPoint(x: x, y: y)
    }
}

#Preview {
    ZStack {
        DialTicks(count: 60, length: 8)
            .stroke(Palette.accent.opacity(.strong), lineWidth: 1)

        DialTicks(count: 12, length: 13)
            .stroke(Palette.accentStrong, lineWidth: 1.5)
    }
    .frame(width: 214, height: 214)
    .padding()
    .background(Palette.background)
}
