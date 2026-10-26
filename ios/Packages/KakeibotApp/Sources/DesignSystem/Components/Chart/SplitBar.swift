import SwiftUI

public struct SplitBar: View {
    let ratio: Double
    let leading: Color
    let trailing: Color
    let height: CGFloat

    public init(
        _ ratio: Double,
        leading: Color,
        trailing: Color,
        height: CGFloat = 8
    ) {
        self.ratio = ratio
        self.leading = leading
        self.trailing = trailing
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack(spacing: Self.gap) {
                if clamped > 0 {
                    Capsule()
                        .fill(leading)
                        .frame(width: width(in: proxy.size.width))
                }

                if clamped < 1 {
                    Capsule()
                        .fill(trailing)
                }
            }
        }
        .frame(height: height)
        .animation(.snappy, value: ratio)
    }
}

private extension SplitBar {
    static let gap: CGFloat = 2

    var clamped: Double {
        min(max(ratio, 0), 1)
    }

    func width(in total: CGFloat) -> CGFloat {
        let gap = clamped < 1 ? Self.gap : 0
        return (total - gap) * clamped
    }
}

#Preview {
    SplitBar(0.7, leading: Palette.accent, trailing: Palette.rose)
        .padding()
        .background(Palette.background)
}
