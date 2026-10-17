import SwiftUI

public struct RingButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let systemImage: String
    let style: Style
    let label: String?
    let action: () -> Void

    public init(
        systemImage: String,
        style: Style = .plain,
        label: String? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.style = style
        self.label = label
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(foreground)
                .frame(width: 38, height: 38)
                .background(fill, in: Circle())
                .overlay(Circle().stroke(stroke, lineWidth: 1))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if let label {
                Text(label)
                    .font(.system(size: 9))
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
}

private extension RingButton {
    var foreground: Color {
        switch (isEnabled, style) {
        case (false, _): Palette.dusk
        case (true, .plain): Palette.mist
        case (true, .prominent): Palette.champagne
        case (true, .destructive): Palette.rose
        }
    }

    var stroke: Color {
        switch (isEnabled, style) {
        case (false, _): Palette.line
        case (true, .plain): Palette.gold.opacity(0.35)
        case (true, .prominent): Palette.gold
        case (true, .destructive): Palette.rose.opacity(0.6)
        }
    }

    var fill: Color {
        isEnabled && style == .prominent
            ? Palette.gold.opacity(0.14)
            : Color.clear
    }
}

#Preview {
    HStack(spacing: 24) {
        RingButton(systemImage: "xmark") {}

        RingButton(systemImage: "checkmark", style: .prominent) {}

        RingButton(
            systemImage: "trash",
            style: .destructive,
            label: "削除"
        ) {}
    }
    .padding()
    .background(Palette.night)
}
