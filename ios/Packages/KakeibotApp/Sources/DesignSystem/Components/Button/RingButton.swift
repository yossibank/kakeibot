import SwiftUI

public struct RingButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: LocalizedStringKey
    let systemImage: String
    let isProminent: Bool
    let action: () -> Void

    public init(
        _ title: LocalizedStringKey,
        systemImage: String,
        isProminent: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isProminent = isProminent
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

private extension RingButton {
    var foreground: Color {
        switch (isEnabled, isProminent) {
        case (false, _): Palette.dusk
        case (true, true): Palette.champagne
        case (true, false): Palette.mist
        }
    }

    var stroke: Color {
        switch (isEnabled, isProminent) {
        case (false, _): Palette.line
        case (true, true): Palette.gold
        case (true, false): Palette.gold.opacity(0.35)
        }
    }

    var fill: Color {
        isEnabled && isProminent ? Palette.gold.opacity(0.14) : Color.clear
    }
}

#Preview {
    HStack(spacing: 24) {
        RingButton("キャンセル", systemImage: "xmark") {}

        RingButton("保存", systemImage: "checkmark", isProminent: true) {}

        RingButton("保存", systemImage: "checkmark", isProminent: true) {}
            .disabled(true)
    }
    .padding()
    .background(Palette.night)
}
