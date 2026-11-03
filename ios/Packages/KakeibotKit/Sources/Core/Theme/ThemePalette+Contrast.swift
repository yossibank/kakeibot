import Foundation

public extension ThemePalette {
    var unreadableRoles: [Role] {
        Self.readableRoles.compactMap { role, minimum in
            let lowest = Self.surfaces.map { Self.contrast(self[role], self[$0]) }.min() ?? 0
            return lowest < minimum ? role : nil
        }
    }

    var isLight: Bool {
        let onBlack = Self.contrast(backgroundTop, 0x000000)
        let onWhite = Self.contrast(backgroundTop, 0xFFFFFF)
        return onBlack > onWhite
    }

    static func contrast(
        _ first: UInt32,
        _ second: UInt32
    ) -> Double {
        let firstLuminance = luminance(first)
        let secondLuminance = luminance(second)
        let lighter = max(firstLuminance, secondLuminance)
        let darker = min(firstLuminance, secondLuminance)

        return (lighter + 0.05) / (darker + 0.05)
    }
}

extension ThemePalette {
    static let surfaces: [Role] = [
        .backgroundTop,
        .backgroundBottom,
        .panel,
        .cardTop,
        .cardBottom
    ]
}

private extension ThemePalette {
    static let readableRoles: [(Role, Double)] = [
        (.accent, 3),
        (.accentStrong, 4.5),
        (.text, 4.5),
        (.subtext, 3),
        (.hint, 3)
    ]

    static let luminanceWeights = [0.2126, 0.7152, 0.0722]

    static func luminance(_ rgb: UInt32) -> Double {
        let channels = [rgb >> 16, rgb >> 8, rgb].map { value in
            let ratio = Double(value & 0xFF) / 255
            let linear = (ratio + 0.055) / 1.055
            return ratio <= 0.04045 ? ratio / 12.92 : pow(linear, 2.4)
        }

        return zip(channels, Self.luminanceWeights).map { $0 * $1 }.reduce(0, +)
    }
}
