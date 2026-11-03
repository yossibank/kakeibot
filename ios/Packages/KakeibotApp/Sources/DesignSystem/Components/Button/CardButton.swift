import SwiftUI

public struct CardButton: View {
    let title: String
    let style: Style
    let height: CGFloat
    let action: () -> Void

    public init(
        _ title: String,
        style: Style,
        height: CGFloat = 48,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            label
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

public extension CardButton {
    enum Style {
        case filled
        case outlined(Color)
    }
}

private extension CardButton {
    @ViewBuilder
    var label: some View {
        switch style {
        case .filled:
            Text(title)
                .textFont(.subheadline, weight: .bold)
                .frame(maxWidth: .infinity, minHeight: height)
                .goldFace()

        case let .outlined(color):
            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: height)
                .overlay {
                    Capsule()
                        .stroke(color.opacity(.medium), lineWidth: 1)
                }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        CardButton("使う", style: .filled) {}

        CardButton("選んでください", style: .filled) {}
            .disabled(true)

        CardButton("やめる", style: .outlined(Palette.subtext)) {}
    }
    .padding()
    .background(Palette.background)
}
