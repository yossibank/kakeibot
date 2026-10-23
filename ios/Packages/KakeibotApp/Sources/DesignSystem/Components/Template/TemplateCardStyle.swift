import Core
import SwiftUI

enum TemplateCardStyle {
    static var fill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var gloss: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.08), .white.opacity(0)],
            startPoint: .topLeading,
            endPoint: .center
        )
    }

    static var foil: AngularGradient {
        AngularGradient(
            colors: [
                Palette.accentStrong.opacity(.strong),
                Palette.accent.opacity(.medium),
                Palette.accentDeep.opacity(.medium),
                Palette.accent.opacity(.medium),
                Palette.accentStrong.opacity(.strong)
            ],
            center: .center
        )
    }
}

public extension View {
    func templateCardFace(
        cornerRadius: CGFloat,
        shadowRadius: CGFloat
    ) -> some View {
        modifier(
            TemplateCardFace(
                cornerRadius: cornerRadius,
                shadowRadius: shadowRadius
            )
        )
    }
}

private struct TemplateCardFace: ViewModifier {
    @Environment(\.themeStyle.corner) private var corner

    let cornerRadius: CGFloat
    let shadowRadius: CGFloat

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner.radius(cornerRadius))

        return content
            .background {
                ZStack {
                    shape
                        .fill(TemplateCardStyle.fill)

                    shape
                        .fill(TemplateCardStyle.gloss)
                }
            }
            .overlay {
                shape
                    .strokeBorder(TemplateCardStyle.foil, lineWidth: 1.2)
            }
            .overlay {
                shape
                    .inset(by: 4)
                    .strokeBorder(
                        Palette.accent.opacity(.subtle),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: Palette.shadow.opacity(0.35), radius: 3, y: 2)
            .shadow(
                color: Palette.shadow.opacity(0.55),
                radius: shadowRadius,
                y: shadowRadius * 0.7
            )
    }
}
