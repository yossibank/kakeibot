import DesignSystem
import SwiftUI

struct AssetsBalanceTrend: View {
    static let netWorthDash: [CGFloat] = [4, 3]

    let totals: [Int]
    let netWorths: [Int]?

    var body: some View {
        GeometryReader { proxy in
            let points = points(of: totals, in: proxy.size)

            let netWorthPoints = netWorths.map { values in
                self.points(of: values, in: proxy.size)
            }

            ZStack {
                if let netWorthPoints {
                    Path { path in
                        path.addLines(netWorthPoints)
                    }
                    .stroke(
                        Palette.accent.opacity(.strong),
                        style: StrokeStyle(
                            lineWidth: 1.2,
                            lineJoin: .round,
                            dash: Self.netWorthDash
                        )
                    )
                }

                Path { path in
                    path.addLines(points)
                }
                .stroke(
                    Palette.accent,
                    style: StrokeStyle(lineWidth: 1.6, lineJoin: .round)
                )

                ForEach(points.indices, id: \.self) { index in
                    let isLast = index == points.count - 1
                    let size: CGFloat = isLast ? 8 : 4
                    let color = isLast ? Palette.accentStrong : Palette.accent

                    Circle()
                        .fill(color)
                        .frame(width: size, height: size)
                        .position(points[index])
                }
            }
        }
    }
}

private extension AssetsBalanceTrend {
    func points(
        of values: [Int],
        in size: CGSize
    ) -> [CGPoint] {
        let all = totals + (netWorths ?? [])
        let low = all.min() ?? 0
        let high = all.max() ?? 0
        let spread = max(high - low, 1)
        let count = max(values.count, 1)
        let range = CGFloat(spread)
        let step = size.width / CGFloat(count)
        let inset: CGFloat = 6

        return values.enumerated().map { index, total in
            let ratio = high == low ? 0.5 : CGFloat(total - low) / range
            let x = step * (CGFloat(index) + 0.5)
            let y = inset + (size.height - inset * 2) * (1 - ratio)

            return CGPoint(x: x, y: y)
        }
    }
}
