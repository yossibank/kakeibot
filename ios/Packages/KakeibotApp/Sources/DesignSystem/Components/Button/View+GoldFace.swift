import SwiftUI

extension View {
    func goldFace() -> some View {
        modifier(GoldFace())
    }
}

private struct GoldFace: ViewModifier {
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

private extension GoldFace {
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

private extension GoldFace {
    static var gold: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.mix(with: Palette.accentStrong, by: 0.3),
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
            [Palette.accentStrong.opacity(.strong), Palette.accent.opacity(.soft)]
        } else {
            [Palette.accent.opacity(.muted), Palette.accent.opacity(.subtle)]
        }

        return LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
    }

    var glow: Color {
        isEnabled ? Palette.glow.opacity(.muted) : .clear
    }
}
