import Foundation

public extension ThemePalette {
    init(
        background: UInt32,
        surface: UInt32,
        text: UInt32,
        subtext: UInt32,
        accent: UInt32
    ) {
        let onBlack = Self.contrast(background, 0x000000)
        let onWhite = Self.contrast(background, 0xFFFFFF)
        let mixes = onBlack > onWhite ? Mixes.light : Mixes.dark
        let (cardTarget, cardRatio) = mixes.cardBottom
        let cardBottom = (cardTarget ?? background, cardRatio)

        self.init(
            backgroundTop: background,
            backgroundBottom: Self.mix(background, mixes.backgroundBottom),
            panel: Self.mix(background, mixes.panel),
            cardTop: surface,
            cardBottom: Self.mix(surface, cardBottom),
            line: Self.mix(surface, (text, 0.12)),
            accent: accent,
            accentDeep: Self.mix(accent, mixes.accentDeep),
            accentStrong: Self.mix(accent, mixes.accentStrong),
            text: text,
            subtext: subtext,
            hint: Self.mix(subtext, (background, 0.12))
        )
    }
}

private extension ThemePalette {
    struct Mixes: Sendable {
        let backgroundBottom: (UInt32, Double)
        let panel: (UInt32, Double)
        let cardBottom: (UInt32?, Double)
        let accentDeep: (UInt32, Double)
        let accentStrong: (UInt32, Double)
    }

    static func mix(
        _ color: UInt32,
        _ target: (UInt32, Double)
    ) -> UInt32 {
        let (other, ratio) = target

        let channels = [UInt32(16), 8, 0].map { shift in
            let from = Double((color >> shift) & 0xFF)
            let to = Double((other >> shift) & 0xFF)

            return UInt32((from + (to - from) * ratio).rounded()) << shift
        }

        return channels.reduce(0, |)
    }
}

private extension ThemePalette.Mixes {
    static let dark = Self(
        backgroundBottom: (0x000000, 0.6),
        panel: (0x000000, 0.35),
        cardBottom: (0x000000, 0.55),
        accentDeep: (0x000000, 0.35),
        accentStrong: (0xFFFFFF, 0.6)
    )

    static let light = Self(
        backgroundBottom: (0x000000, 0.04),
        panel: (0x000000, 0.02),
        cardBottom: (nil, 0.5),
        accentDeep: (0xFFFFFF, 0.35),
        accentStrong: (0x000000, 0.45)
    )
}
