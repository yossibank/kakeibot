import Core

extension ThemePalette {
    var paper: UInt32 {
        isDark ? Self.mix(cardTop, text, by: 0.1) : cardTop
    }

    var paperEdge: UInt32 {
        isDark ? Self.mix(cardTop, text, by: 0.3) : Self.mix(cardTop, accent, by: 0.35)
    }
}

private extension ThemePalette {
    var isDark: Bool {
        Self.luminance(of: cardTop) < 0.4
    }

    static func channels(of rgb: UInt32) -> [Double] {
        [16, 8, 0].map { shift in
            Double((rgb >> UInt32(shift)) & 0xFF)
        }
    }

    static func luminance(of rgb: UInt32) -> Double {
        let values = channels(of: rgb)
        return (0.299 * values[0] + 0.587 * values[1] + 0.114 * values[2]) / 255
    }

    static func mix(
        _ base: UInt32,
        _ other: UInt32,
        by ratio: Double
    ) -> UInt32 {
        zip(channels(of: base), channels(of: other)).reduce(0) { result, pair in
            let value = UInt32((pair.0 + (pair.1 - pair.0) * ratio).rounded())
            return result << 8 | value
        }
    }
}
