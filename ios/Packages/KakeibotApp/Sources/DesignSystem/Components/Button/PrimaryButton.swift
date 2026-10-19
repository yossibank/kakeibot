import SwiftUI

public struct PrimaryButton: View {
    @Environment(\.isEnabled) private var isEnabled

    let title: String
    let action: () -> Void

    public init(
        _ title: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background {
                    face
                }
                .overlay {
                    Capsule()
                        .strokeBorder(rim, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .shadow(color: glow, radius: 14, y: 6)
    }
}

private extension PrimaryButton {
    @ViewBuilder
    var face: some View {
        if isEnabled {
            Capsule()
                .fill(Self.gold)
                .overlay {
                    Capsule()
                        .fill(Self.sheen)
                }
        } else {
            Capsule()
                .fill(Palette.card)
        }
    }
}

private extension PrimaryButton {
    static var gold: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.mix(with: Palette.accentLight, by: 0.3),
                Palette.accent,
                Palette.accent.mix(with: Palette.accentDeep, by: 0.45)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.22), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    var textColor: Color {
        isEnabled ? Palette.backgroundBottom : Palette.subtext
    }

    var rim: LinearGradient {
        let colors = if isEnabled {
            [
                Palette.accentLight.opacity(.strong),
                Palette.accent.opacity(.soft)
            ]
        } else {
            [Palette.accent.opacity(.muted), Palette.accent.opacity(.subtle)]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var glow: Color {
        isEnabled ? Palette.accent.opacity(.muted) : .clear
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("¥12,800 を記録する") {}

        PrimaryButton("金額を入れてください") {}
            .disabled(true)
    }
    .padding()
    .background(Palette.background)
}
