import SwiftUI

public struct HeaderButton: View {
    let systemImage: String
    let title: String?
    let action: () -> Void

    public init(
        systemImage: String,
        title: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.sans(.body, weight: .light))

                if let title {
                    Text(title)
                        .font(.serif(.body))
                        .tracking(2)
                }
            }
            .foregroundStyle(Palette.gold)
            .padding(.horizontal, horizontalPadding)
            .frame(minWidth: Self.height, minHeight: Self.height)
            .background(Self.fill, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(Self.stroke, lineWidth: 1)
            }
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
                Palette.gold.opacity(.subtle),
                Palette.gold.opacity(.faint)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var stroke: LinearGradient {
        LinearGradient(
            colors: [
                Palette.gold.opacity(.medium),
                Palette.gold.opacity(.soft)
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
        HeaderButton(systemImage: "gearshape") {}

        HeaderButton(
            systemImage: "arrow.left.arrow.right",
            title: "振替"
        ) {}
    }
    .padding()
    .background(Palette.night)
}
