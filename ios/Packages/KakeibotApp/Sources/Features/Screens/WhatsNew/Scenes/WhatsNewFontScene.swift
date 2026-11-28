import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct WhatsNewFontScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .choose:
            grid
                .whatsNewTapped()

        case .loading, .ready:
            grid
        }
    }
}

extension WhatsNewFontScene {
    enum Step: Hashable, Sendable {
        case choose
        case loading
        case ready
    }
}

private extension WhatsNewFontScene {
    var grid: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                tile(.mincho)
                tile(.gothic)
            }

            HStack(spacing: 8) {
                tile(.boldMincho)
                tile(.textbook)
            }
        }
    }

    func tile(_ font: ThemeFont) -> some View {
        let isChosen = font == chosen
        let border = isChosen ? Palette.accent : Palette.hairline

        return VStack(spacing: 4) {
            sample(font)
                .frame(height: 20)

            Text(font.title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 60, height: 52)
        .background(Palette.field, in: .rect(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(border, lineWidth: isChosen ? 1.5 : 1)
        }
    }

    @ViewBuilder
    func sample(_ font: ThemeFont) -> some View {
        switch phase(of: font) {
        case .ready:
            Text(Yen.text(Self.sampleAmount))
                .font(.display(
                    size: 14,
                    weight: .bold,
                    in: ThemeFontLoader.shared.shownFont(for: font)
                ))
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

        case .loading:
            Image(systemName: "hourglass")
                .sansFont(.caption)
                .foregroundStyle(Palette.accent)

        case .notLoaded, .checking:
            Image(systemName: "arrow.down.circle")
                .sansFont(.caption)
                .foregroundStyle(Palette.accent)
        }
    }
}

private extension WhatsNewFontScene {
    static let sampleAmount = 1280

    var chosen: ThemeFont {
        step == .choose ? .mincho : .textbook
    }

    var textbookPhase: ThemeFontLoader.Phase {
        switch step {
        case .choose: .notLoaded
        case .loading: .loading
        case .ready: .ready
        }
    }

    func phase(of font: ThemeFont) -> ThemeFontLoader.Phase {
        switch font {
        case .textbook: textbookPhase
        case .boldMincho: .notLoaded
        default: .ready
        }
    }
}
