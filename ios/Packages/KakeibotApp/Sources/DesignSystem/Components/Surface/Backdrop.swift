import Core
import SwiftUI

public struct Backdrop: View {
    @Environment(\.themeStyle.backdrop) private var backdrop

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(Palette.background)
            .overlay {
                pattern
                    .allowsHitTesting(false)
            }
    }
}

private extension Backdrop {
    @ViewBuilder
    var pattern: some View {
        switch backdrop {
        case .plain:
            EmptyView()
        case .washi:
            Canvas { context, size in
                Self.drawFibers(in: &context, size: size)
            }
        case .grid:
            Canvas { context, size in
                Self.drawGrid(in: &context, size: size)
            }
        }
    }
}

private extension Backdrop {
    static let gridInk = Palette.accent.opacity(0.16)
    static let fiberInk = Palette.accent.opacity(0.2)
    static let gridStep: CGFloat = 20
    static let fiberArea: CGFloat = 180

    static func drawGrid(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        var path = Path()

        for x in stride(from: gridStep, to: size.width, by: gridStep) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for y in stride(from: gridStep, to: size.height, by: gridStep) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        context.stroke(path, with: .color(gridInk), lineWidth: 0.6)
    }

    static func drawFibers(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        var random = SeededRandom()
        var path = Path()
        let count = Int(size.width * size.height / fiberArea)

        for _ in 0..<count {
            let start = CGPoint(
                x: random.next() * size.width,
                y: random.next() * size.height
            )

            let angle = random.next() * .pi
            let length = 6 + random.next() * 12

            let end = CGPoint(
                x: start.x + cos(angle) * length,
                y: start.y + sin(angle) * length
            )

            path.move(to: start)
            path.addLine(to: end)
        }

        context.stroke(path, with: .color(fiberInk), lineWidth: 0.8)
    }
}

private struct SeededRandom {
    private var state: UInt64 = 0x9E37_79B9_7F4A_7C15
}

private extension SeededRandom {
    mutating func next() -> CGFloat {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407

        let value = Double(state >> 11) / Double(1 << 53)
        return CGFloat(value)
    }
}

#Preview {
    Backdrop()
        .environment(\.themeStyle.backdrop, .washi)
}
