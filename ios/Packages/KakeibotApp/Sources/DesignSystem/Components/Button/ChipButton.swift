import SwiftUI

public struct ChipButton<Content: View>: View {
    let isSelected: Bool
    let size: Size
    let outline: Outline
    let width: Width
    let action: () -> Void
    let content: Content

    public init(
        isSelected: Bool = false,
        size: Size = .regular,
        outline: Outline = .solid,
        width: Width = .fit,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.isSelected = isSelected
        self.size = size
        self.outline = outline
        self.width = width
        self.action = action
        self.content = content()
    }

    public var body: some View {
        Button(action: action) {
            label
                .foregroundStyle(foreground)
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: maxWidth, minHeight: size.height)
                .background(fill, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(stroke, style: strokeStyle)
                }
                .contentShape(Capsule())
                .tapArea(tapOutsets)
        }
        .buttonStyle(.plain)
    }
}

public extension ChipButton where Content == ChipLabel {
    init(
        _ title: String,
        systemImage: String? = nil,
        isSelected: Bool = false,
        size: Size = .regular,
        outline: Outline = .solid,
        action: @escaping () -> Void
    ) {
        self.init(
            isSelected: isSelected,
            size: size,
            outline: outline,
            action: action
        ) {
            ChipLabel(title: title, systemImage: systemImage)
        }
    }
}

public extension ChipButton {
    enum Size: Sendable {
        case regular
        case large
    }

    enum Outline: Sendable {
        case solid
        case dashed
    }

    enum Width: Sendable {
        case fit
        case fill
    }
}

private extension ChipButton {
    @ViewBuilder
    var label: some View {
        switch size {
        case .regular:
            content
                .textFont(size: .caption)
        case .large:
            content
                .textFont(.subheadline)
        }
    }
}

private extension ChipButton {
    static var minimumTapHeight: CGFloat {
        44
    }

    static var fillPadding: CGFloat {
        4
    }

    var foreground: Color {
        switch outline {
        case .solid: Palette.text
        case .dashed: Palette.accent
        }
    }

    var fill: Color {
        isSelected ? Palette.accent.opacity(.subtle) : Color.clear
    }

    var stroke: Color {
        switch (outline, isSelected) {
        case (.dashed, _): Palette.accent.opacity(.medium)
        case (.solid, true): Palette.accent
        case (.solid, false): Palette.accent.opacity(.soft)
        }
    }

    var horizontalPadding: CGFloat {
        switch width {
        case .fit: size.padding
        case .fill: Self.fillPadding
        }
    }

    var maxWidth: CGFloat? {
        switch width {
        case .fit: nil
        case .fill: .infinity
        }
    }

    var strokeStyle: StrokeStyle {
        switch outline {
        case .solid: StrokeStyle(lineWidth: 1)
        case .dashed: .dashed
        }
    }

    var tapOutsets: EdgeInsets {
        let outset = max(0, (Self.minimumTapHeight - size.height) / 2)

        return EdgeInsets(
            top: outset,
            leading: 0,
            bottom: outset,
            trailing: 0
        )
    }
}

private extension ChipButton.Size {
    var height: CGFloat {
        switch self {
        case .regular: 34
        case .large: 40
        }
    }

    var padding: CGFloat {
        switch self {
        case .regular: 12
        case .large: 16
        }
    }
}

public struct ChipLabel: View {
    let title: String
    let systemImage: String?

    public var body: some View {
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
            }

            Text(title)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            ChipButton("なし", isSelected: true) {}

            ChipButton("¥110") {}

            ChipButton("今の入力を保存", systemImage: "plus", outline: .dashed) {}
        }

        HStack(spacing: 8) {
            ChipButton("今日", isSelected: true, size: .large) {}

            ChipButton("昨日", size: .large) {}
        }
    }
    .padding()
    .background(Palette.background)
}
