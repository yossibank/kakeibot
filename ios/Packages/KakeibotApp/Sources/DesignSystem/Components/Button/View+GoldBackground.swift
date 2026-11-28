import SwiftUI

public extension View {
    func goldBackground() -> some View {
        modifier(GoldBackground())
    }
}

private struct GoldBackground: ViewModifier {
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .foregroundStyle(textColor)
            .background {
                face
            }
            .overlay {
                Capsule()
                    .strokeBorder(rim, lineWidth: 1)
            }
            .contentShape(Capsule())
            .glow(glow, radius: 14, y: 6)
    }
}

private extension GoldBackground {
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

private extension GoldBackground {
    static var gold: LinearGradient {
        LinearGradient(
            colors: [
                Palette.goldFace.mix(with: Palette.goldLight, by: 0.3),
                Palette.goldFace,
                Palette.goldFace.mix(with: Palette.goldShade, by: 0.45)
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
            [Palette.goldLight.opacity(.strong), Palette.accent.opacity(.soft)]
        } else {
            [Palette.accent.opacity(.muted), Palette.accent.opacity(.subtle)]
        }

        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var glow: Color {
        isEnabled ? Palette.glow.opacity(.muted) : .clear
    }
}
