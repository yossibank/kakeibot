import Core
import SwiftUI
import UIKit

public extension View {
    func palette(_ palette: ThemePalette?) -> some View {
        background {
            PaletteScene(palette: palette)
        }
    }
}

private struct PaletteScene: UIViewRepresentable {
    let palette: ThemePalette?

    func makeUIView(context: Context) -> PaletteSceneView {
        PaletteSceneView()
    }

    func updateUIView(
        _ view: PaletteSceneView,
        context: Context
    ) {
        view.palette = palette
    }
}

private final class PaletteSceneView: UIView {
    var palette: ThemePalette? {
        didSet {
            apply()
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        apply()
    }

    func apply() {
        guard let scene = window?.windowScene else {
            return
        }

        guard let palette else {
            scene.traitOverrides.remove(PaletteTrait.self)
            scene.traitOverrides.remove(UITraitUserInterfaceStyle.self)
            return
        }

        let style: UIUserInterfaceStyle = palette.isLight ? .light : .dark
        scene.traitOverrides[PaletteTrait.self] = palette
        scene.traitOverrides.userInterfaceStyle = style
    }
}
