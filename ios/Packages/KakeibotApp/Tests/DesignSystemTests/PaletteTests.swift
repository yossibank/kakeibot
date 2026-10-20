import Core
import DesignSystem
import SwiftUI
import Testing

@MainActor
struct PaletteTests {
    @Test
    func usesNightByDefault() {
        let environment = EnvironmentValues()

        let accent = Palette.accent.resolve(in: environment)

        #expect(rgb(accent) == 0xCDAA6B)
    }

    @Test
    func followsTheme() {
        var environment = EnvironmentValues()
        environment.palette = Self.forest

        let accent = Palette.accent.resolve(in: environment)
        let text = Palette.text.resolve(in: environment)

        #expect(rgb(accent) == 0x7FD1A8)
        #expect(rgb(text) == 0xF0F5F2)
    }

    @Test
    func drawsWithTheme() {
        let content = Rectangle()
            .fill(Palette.accent)
            .frame(width: 1, height: 1)
            .environment(\.palette, Self.forest)

        let pixel = ImageRenderer(content: content).cgImage.flatMap(rgb)

        #expect(pixel == 0x7FD1A8)
    }

    @Test
    func changesMeaningColorsByBrightness() {
        var environment = EnvironmentValues()
        environment.palette = Self.forest
        environment.colorScheme = .dark

        let dark = Palette.rose.resolve(in: environment)

        environment.colorScheme = .light

        let light = Palette.rose.resolve(in: environment)

        #expect(rgb(dark) == 0xE3A3A3)
        #expect(rgb(light) == 0xB04A4A)
    }
}

private extension PaletteTests {
    static let forest = ThemePalette(
        backgroundTop: 0x143C32,
        backgroundBottom: 0x04130E,
        panel: 0x0B2620,
        cardTop: 0x12352C,
        cardBottom: 0x061712,
        line: 0x1F4A3E,
        accent: 0x7FD1A8,
        accentDeep: 0x3F7A5C,
        accentLight: 0xD8F2E4,
        text: 0xF0F5F2,
        subtext: 0x8FB3A5,
        hint: 0x7A9C8F
    )

    func rgb(_ color: Color.Resolved) -> UInt32 {
        let components = [color.red, color.green, color.blue].map { value in
            UInt32((value * 255).rounded())
        }

        return components[0] << 16 | components[1] << 8 | components[2]
    }

    func rgb(_ image: CGImage) -> UInt32? {
        var bytes = [UInt8](repeating: 0, count: 4)
        let space = CGColorSpace(name: CGColorSpace.sRGB)

        guard
            let space,
            let context = CGContext(
                data: &bytes,
                width: 1,
                height: 1,
                bitsPerComponent: 8,
                bytesPerRow: 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))

        return UInt32(bytes[0]) << 16 | UInt32(bytes[1]) << 8 | UInt32(bytes[2])
    }
}
