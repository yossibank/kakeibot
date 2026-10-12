import SwiftUI

public struct RingButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: LocalizedStringKey
    let systemImage: String
    let style: Style
    let action: () -> Void

    public init(
        _ title: LocalizedStringKey,
        systemImage: String,
        style: Style = .plain,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
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
        .accessibilityLabel(title)
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
        isEnabled && style == .prominent ? Palette.gold.opacity(0.14) : Color.clear
    }
}

#Preview {
    HStack(spacing: 24) {
        RingButton("閉じる", systemImage: "xmark") {}

        RingButton("保存", systemImage: "checkmark", style: .prominent) {}

        RingButton("消す", systemImage: "trash", style: .destructive) {}
    }
    .padding()
    .background(Palette.night)
}
