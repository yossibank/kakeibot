import Foundation

public extension ThemePalette {
    enum Semantic: String, CaseIterable, Codable, Sendable {
        case rose
        case amber
        case holiday
        case saturday

        public var light: UInt32 {
            switch self {
            case .rose: 0xB04A4A
            case .amber: 0xA8581A
            case .holiday: 0xC0392B
            case .saturday: 0x2D63B5
            }
        }

        public var dark: UInt32 {
            switch self {
            case .rose: 0xE3A3A3
            case .amber: 0xE89B57
            case .holiday: 0xEE8A84
            case .saturday: 0x8DB0EA
            }
        }
    }

    func color(_ semantic: Semantic) -> UInt32 {
        let base = isLight ? semantic.light : semantic.dark

        if lowestContrast(of: base) >= Self.semanticMinimum {
            return base
        }

        let hsl = HSL(base)
        let directions = isLight ? [-1.0, 1.0] : [1.0, -1.0]
        let shifts = directions.map { shifted(hsl, direction: $0) }

        if let found = shifts.compactMap(\.found).first {
            return found
        }

        let candidates = [base] + shifts.map(\.best)

        return candidates.max { first, second in
            lowestContrast(of: first) < lowestContrast(of: second)
        } ?? base
    }
}

private extension ThemePalette {
    struct Shift {
        let found: UInt32?
        let best: UInt32
    }

    struct HSL {
        let hue: Double
        let saturation: Double
        let lightness: Double

        init(
            hue: Double,
            saturation: Double,
            lightness: Double
        ) {
            self.hue = hue
            self.saturation = saturation
            self.lightness = lightness
        }
    }

    static let semanticMinimum = 3.0
    static let semanticSteps = 100

    func lowestContrast(of color: UInt32) -> Double {
        Self.surfaces.map { Self.contrast(color, self[$0]) }.min() ?? 0
    }

    func shifted(
        _ hsl: HSL,
        direction: Double
    ) -> Shift {
        var best = hsl.rgb

        for step in 1...Self.semanticSteps {
            let amount = direction * Double(step) / Double(Self.semanticSteps)
            let color = hsl.lightness(by: amount).rgb

            if lowestContrast(of: color) >= Self.semanticMinimum {
                return Shift(found: color, best: color)
            }

            if lowestContrast(of: color) > lowestContrast(of: best) {
                best = color
            }
        }

        return Shift(found: nil, best: best)
    }
}

private extension ThemePalette.HSL {
    var rgb: UInt32 {
        let chroma = (1 - abs(2 * lightness - 1)) * saturation
        let sector = hue / 60
        let sectorRemainder = sector.truncatingRemainder(dividingBy: 2)
        let mid = chroma * (1 - abs(sectorRemainder - 1))
        let offset = lightness - chroma / 2
        let parts: (Double, Double, Double) = switch Int(sector) {
        case 0: (chroma, mid, 0)
        case 1: (mid, chroma, 0)
        case 2: (0, chroma, mid)
        case 3: (0, mid, chroma)
        case 4: (mid, 0, chroma)
        default: (chroma, 0, mid)
        }

        func byte(_ value: Double) -> UInt32 {
            let scaled = ((value + offset) * 255).rounded()
            return UInt32(scaled)
        }

        return byte(parts.0) << 16 | byte(parts.1) << 8 | byte(parts.2)
    }

    init(_ rgb: UInt32) {
        let red = Double((rgb >> 16) & 0xFF) / 255
        let green = Double((rgb >> 8) & 0xFF) / 255
        let blue = Double(rgb & 0xFF) / 255
        let high = max(red, green, blue)
        let low = min(red, green, blue)
        let delta = high - low
        let lightness = (high + low) / 2

        guard delta > 0 else {
            self.init(hue: 0, saturation: 0, lightness: lightness)
            return
        }

        let saturation = delta / (1 - abs(2 * lightness - 1))

        let sector = switch high {
        case red: ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
        case green: (blue - red) / delta + 2
        default: (red - green) / delta + 4
        }

        let hue = (sector < 0 ? sector + 6 : sector) * 60

        self.init(hue: hue, saturation: saturation, lightness: lightness)
    }

    func lightness(by amount: Double) -> ThemePalette.HSL {
        let shifted = lightness + amount
        let lowerClamped = max(shifted, 0)
        let clamped = min(lowerClamped, 1)

        return ThemePalette.HSL(hue: hue, saturation: saturation, lightness: clamped)
    }
}
