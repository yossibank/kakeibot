import DesignSystem
import SwiftUI

extension View {
    func reviewHero() -> some View {
        padding(20)
            .reviewTicket()
    }

    func reviewTicket() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: ReviewReportRadius.hero)
                    .fill(Palette.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: ReviewReportRadius.hero)
                            .fill(RadialGradient.reviewGlow)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: ReviewReportRadius.hero)
                            .strokeBorder(Palette.accent.opacity(.muted))
                    }
                    .shadow(color: Palette.accent.opacity(.subtle), radius: 16, y: 12)
            }
    }

    func reviewStatGrid() -> some View {
        background(Palette.lit.opacity(.soft))
            .clipShape(.rect(cornerRadius: ReviewReportRadius.panel))
    }
}

private extension RadialGradient {
    static var reviewGlow: RadialGradient {
        RadialGradient(
            colors: [Palette.accent.opacity(.subtle), .clear],
            center: .topTrailing,
            startRadius: 0,
            endRadius: 240
        )
    }
}
