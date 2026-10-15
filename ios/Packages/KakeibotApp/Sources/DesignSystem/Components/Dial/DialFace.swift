import SwiftUI

public struct DialFace: View {
    let isActive: Bool

    public init(isActive: Bool) {
        self.isActive = isActive
    }

    public var body: some View {
        GeometryReader { proxy in
            let scale = Self.scale(for: proxy.size)

            ZStack {
                Circle()
                    .stroke(
                        Palette.gold.opacity(isActive ? 1 : 0.55),
                        lineWidth: 1
                    )
                    .shadow(
                        color: Palette.gold.opacity(isActive ? 0.3 : 0),
                        radius: 16
                    )

                DialTicks(count: 60, length: 9 * scale)
                    .stroke(Palette.gold.opacity(0.8), lineWidth: 1)
                    .padding(12 * scale)

                DialTicks(count: 12, length: 14 * scale)
                    .stroke(Palette.champagne, lineWidth: 1.5)
                    .padding(12 * scale)
            }
        }
    }
}

private extension DialFace {
    static let fullSize: CGFloat = 220

    static func scale(for size: CGSize) -> CGFloat {
        min(min(size.width, size.height) / fullSize, 1)
    }
}

#Preview {
    HStack(spacing: 24) {
        DialFace(isActive: false)
            .frame(width: 160, height: 160)

        DialFace(isActive: true)
            .frame(width: 160, height: 160)
    }
    .padding()
    .background(Palette.night)
}
