import SwiftUI

public struct RingButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let systemImage: String
    let style: Style
    let size: Size
    let label: String?
    let action: () -> Void

    public init(
        systemImage: String,
        style: Style = .plain,
        size: Size = .regular,
        label: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.style = style
        self.size = size
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .sansFont(size.font, weight: size.weight)
                .foregroundStyle(foreground)
                .frame(width: size.diameter, height: size.diameter)
                .background(fill, in: Circle())
                .overlay(Circle().stroke(stroke, lineWidth: 1))
                .frame(width: size.hitSize, height: size.hitSize)
                .tapArea(max(0, (Self.minimumHitSize - size.hitSize) / 2))
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if let label {
                Text(label)
                    .textFont(size: .micro)
                    .tracking(1)
                    .foregroundStyle(foreground)
                    .fixedSize()
                    .offset(y: 11)
                    .allowsHitTesting(false)
            }
        }
    }
}

public extension RingButton {
    enum Style: Sendable {
        case plain
        case prominent
        case destructive
    }

    enum Size: Sendable {
        case regular
        case small
    }
}

private extension RingButton {
    static let minimumHitSize: CGFloat = 44

    var foreground: Color {
        switch (isEnabled, style) {
        case (false, _): Palette.hint
        case (true, .plain): Palette.subtext
        case (true, .prominent): Palette.accentStrong
        case (true, .destructive): Palette.rose
        }
    }

    var stroke: Color {
        switch (isEnabled, style) {
        case (false, _): Palette.line
        case (true, .plain): Palette.accent.opacity(.muted)
        case (true, .prominent): Palette.accent
        case (true, .destructive): Palette.rose.opacity(.medium)
        }
    }

    var fill: Color {
        isEnabled && style == .prominent
            ? Palette.accent.opacity(.subtle)
            : Color.clear
    }
}

private extension RingButton.Size {
    var font: FontSize {
        switch self {
        case .regular: .body
        case .small: .caption
        }
    }

    var weight: Font.Weight {
        switch self {
        case .regular: .light
        case .small: .regular
        }
    }

    var diameter: CGFloat {
        switch self {
        case .regular: 36
        case .small: 24
        }
    }

    var hitSize: CGFloat {
        switch self {
        case .regular: 40
        case .small: 32
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        RingButton(systemImage: "xmark") {}
        RingButton(systemImage: "xmark", size: .small) {}
        RingButton(systemImage: "checkmark", style: .prominent) {}
        RingButton(systemImage: "trash", style: .destructive, label: "削除") {}
    }
    .padding()
    .background(Palette.background)
}
