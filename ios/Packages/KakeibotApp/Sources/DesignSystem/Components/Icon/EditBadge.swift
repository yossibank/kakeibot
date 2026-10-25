import SwiftUI

public struct EditBadge: View {
    private let size: CGFloat
    private let style: Style

    public init(
        size: CGFloat = 18,
        style: Style = .quiet
    ) {
        self.size = size
        self.style = style
    }

    public var body: some View {
        Image(systemName: "pencil")
            .font(.system(size: size * 0.55, weight: weight))
            .foregroundStyle(pencilColor)
            .frame(width: size, height: size)
            .background {
                Circle()
                    .fill(Palette.panel)
                    .overlay {
                        Circle()
                            .fill(tint)
                    }
            }
            .overlay {
                Circle()
                    .stroke(strokeColor, lineWidth: 1)
            }
            .shadow(color: shadowColor, radius: 4, y: 2)
    }
}

public extension EditBadge {
    enum Style: Sendable {
        case quiet
        case button
    }
}

private extension EditBadge {
    var isButton: Bool {
        style == .button
    }

    var weight: Font.Weight {
        isButton ? .semibold : .medium
    }

    var pencilColor: Color {
        isButton ? Palette.accent : Palette.accent.opacity(.strong)
    }

    var tint: Color {
        isButton ? Color.clear : Palette.accent.opacity(.subtle)
    }

    var strokeColor: Color {
        isButton ? Palette.accent : Color.clear
    }

    var shadowColor: Color {
        isButton ? Palette.shadow : Color.clear
    }
}

#Preview {
    HStack(spacing: 16) {
        EditBadge()

        EditBadge(size: 26, style: .button)

        Text("¥150,000")
            .editBadge()
    }
    .padding()
    .background(Palette.background)
}
