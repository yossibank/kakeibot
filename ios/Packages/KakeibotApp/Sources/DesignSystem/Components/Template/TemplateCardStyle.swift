import Core
import SwiftUI

enum TemplateCardStyle {}

extension TemplateCardStyle {
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
                Palette.champagne.opacity(0.9),
                Palette.gold.opacity(0.6),
                Palette.bronze.opacity(0.5),
                Palette.gold.opacity(0.6),
                Palette.champagne.opacity(0.9)
            ],
            center: .center
        )
    }
}

extension View {
    func templateCardFace(
        cornerRadius: CGFloat,
        shadowRadius: CGFloat
    ) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        return background {
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
                .strokeBorder(Palette.gold.opacity(0.1), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.35), radius: 3, y: 2)
        .shadow(
            color: .black.opacity(0.55),
            radius: shadowRadius,
            y: shadowRadius * 0.7
        )
    }
}
