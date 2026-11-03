import Core
import SwiftUI

public struct Backdrop: View {
    @Environment(\.themeStyle.backdrop) private var backdrop

    let scale: CGFloat

    public init(scale: CGFloat = 1) {
        self.scale = scale
    }

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

        case .ruled:
            Canvas { context, size in
                drawRules(in: &context, size: size)
            }

        case .grid:
            Canvas { context, size in
                drawGrid(in: &context, size: size)
            }
        }
    }
}

private extension Backdrop {
    static let ink = Palette.accent.opacity(0.16)
    static let marginInk = Palette.rose.opacity(0.24)
    static let gridStep: CGFloat = 20
    static let ruleStep: CGFloat = 32
    static let marginX: CGFloat = 40

    func drawGrid(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let step = Self.gridStep * scale
        var path = Path()

        for x in stride(from: step, to: size.width, by: step) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }

        for y in stride(from: step, to: size.height, by: step) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }

        context.stroke(path, with: .color(Self.ink), lineWidth: 0.6)
    }

    func drawRules(
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let step = Self.ruleStep * scale
        let marginX = Self.marginX * scale
        var rules = Path()
        var margin = Path()

        for y in stride(from: step, to: size.height, by: step) {
            rules.move(to: CGPoint(x: 0, y: y))
            rules.addLine(to: CGPoint(x: size.width, y: y))
        }

        margin.move(to: CGPoint(x: marginX, y: 0))
        margin.addLine(to: CGPoint(x: marginX, y: size.height))

        context.stroke(rules, with: .color(Self.ink), lineWidth: 0.8)
        context.stroke(margin, with: .color(Self.marginInk), lineWidth: 0.8)
    }
}

#Preview {
    Backdrop()
        .environment(\.themeStyle.backdrop, .ruled)
}
