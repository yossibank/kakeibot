import Core
import Testing

struct ThemeLookTests {
    @Test
    func followsDeviceStyle() {
        let look = ThemeLook.followsDevice

        let light = look.palette(isDark: false)
        let dark = look.palette(isDark: true)

        #expect(light == ThemePreset.white.palette)
        #expect(dark == ThemePreset.black.palette)
    }

    @Test
    func keepsFixedPalette() {
        let look = ThemeLook.fixed(ThemePreset.navy.palette)

        let dark = look.palette(isDark: true)

        #expect(dark == ThemePreset.navy.palette)
    }

    @Test
    func readsSystemChoice() {
        let choice = ThemeChoice("system")

        #expect(choice == .system)
        #expect(choice?.text == "system")
    }
}
