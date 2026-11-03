import DesignSystem
import SwiftUI

struct EntryReceiptShape: Shape {
    let tooth: CGFloat
    let hasTopEdge: Bool
    let hasBottomEdge: Bool

    init(
        tooth: CGFloat,
        hasTopEdge: Bool,
        hasBottomEdge: Bool = true
    ) {
        self.tooth = tooth
        self.hasTopEdge = hasTopEdge
        self.hasBottomEdge = hasBottomEdge
    }

    func path(in rect: CGRect) -> Path {
        let depth = tooth / 2
        let count = max(1, Int((rect.width / tooth).rounded()))
        let step = rect.width / CGFloat(count)

        var path = Path()

        if hasTopEdge {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY + depth))

            for index in 0..<count {
                let left = rect.minX + step * CGFloat(index)

                path.addLine(to: CGPoint(x: left + step / 2, y: rect.minY))
                path.addLine(to: CGPoint(x: left + step, y: rect.minY + depth))
            }
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }

        if hasBottomEdge {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - depth))

            for index in 0..<count {
                let right = rect.maxX - step * CGFloat(index)

                path.addLine(to: CGPoint(x: right - step / 2, y: rect.maxY))
                path.addLine(to: CGPoint(x: right - step, y: rect.maxY - depth))
            }
        } else {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        }

        path.closeSubpath()

        return path
    }
}

struct EntryReceiptRule: View {
    let style: Style

    var body: some View {
        switch style {
        case .dashed:
            EntryRuleShape()
                .stroke(
                    Palette.subtext.opacity(0.6),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                .frame(height: 1)

        case .double:
            VStack(spacing: 2) {
                Rectangle()
                    .fill(Palette.text.opacity(0.6))
                    .frame(height: 1)

                Rectangle()
                    .fill(Palette.text.opacity(0.6))
                    .frame(height: 1)
            }
        }
    }
}

extension EntryReceiptRule {
    enum Style {
        case dashed
        case double
    }
}

struct EntryRuleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))

        return path
    }
}
