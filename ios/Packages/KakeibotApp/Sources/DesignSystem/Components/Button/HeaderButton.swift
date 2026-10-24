import SwiftUI

public struct HeaderButton: View {
    let systemImage: String
    let title: String?
    let showsDot: Bool
    let action: () -> Void

    public init(
        systemImage: String,
        title: String? = nil,
        showsDot: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.showsDot = showsDot
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .sansFont(.body, weight: .light)

                if let title {
                    Text(title)
                        .displayFont(.body)
                        .tracking(2)
                }
            }
            .foregroundStyle(Palette.accent)
            .padding(.horizontal, horizontalPadding)
            .frame(minWidth: Self.height, minHeight: Self.height)
            .background(Self.fill, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Self.stroke, lineWidth: 1)
            }
            .overlay(alignment: .topTrailing) {
                if showsDot {
                    Circle()
                        .fill(Palette.accentStrong)
                        .frame(width: 8, height: 8)
                        .shadow(color: Palette.glow, radius: 4)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.snappy, value: showsDot)
            .frame(minHeight: 44)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension HeaderButton {
    static let height: CGFloat = 40

    static var fill: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.subtle),
                Palette.accent.opacity(.faint)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var stroke: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.medium),
                Palette.accent.opacity(.soft)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var horizontalPadding: CGFloat {
        title == nil ? 0 : 16
    }
}

#Preview {
    HStack(spacing: 24) {
        HeaderButton(
            systemImage: "gearshape",
            showsDot: true
        ) {}

        HeaderButton(
            systemImage: "arrow.left.arrow.right",
            title: "振替"
        ) {}
    }
    .padding()
    .background(Palette.background)
}
