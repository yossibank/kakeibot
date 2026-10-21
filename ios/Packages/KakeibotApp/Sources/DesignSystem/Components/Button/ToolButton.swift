import SwiftUI

public struct ToolButton: View {
    let systemImage: String
    let isOn: Bool
    let action: () -> Void

    public init(
        systemImage: String,
        isOn: Bool = false,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.isOn = isOn
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.accent)
                .frame(width: 36, height: 36)
                .background(fill, in: Circle())
                .overlay {
                    Circle()
                        .stroke(ring, lineWidth: 1)
                }
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension ToolButton {
    var fill: Color {
        isOn ? Palette.accent.opacity(.subtle) : .clear
    }

    var ring: Color {
        isOn ? Palette.accent : Palette.line
    }
}
