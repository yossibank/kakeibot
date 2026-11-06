import SwiftUI

public struct RatioBar: View {
    let progress: Double
    let tint: Color
    let height: CGFloat

    public init(
        _ progress: Double,
        tint: Color,
        height: CGFloat = 3
    ) {
        self.progress = progress
        self.tint = tint
        self.height = height
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.line)

                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * clamped)
            }
        }
        .frame(height: height)
        .transaction(value: progress) { transaction in
            if !transaction.disablesAnimations {
                transaction.animation = .snappy
            }
        }
    }
}

private extension RatioBar {
    var clamped: Double {
        min(max(progress, 0), 1)
    }
}
