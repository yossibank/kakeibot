import Core
import SwiftUI
import UIKit

public extension View {
    func palette(_ look: ThemeLook?) -> some View {
        background {
            PaletteScene(look: look)
        }
    }
}

private struct PaletteScene: UIViewRepresentable {
    let look: ThemeLook?

    func makeUIView(context: Context) -> PaletteSceneView {
        PaletteSceneView()
    }

    func updateUIView(
        _ view: PaletteSceneView,
        context: Context
    ) {
        view.look = look
    }
}

private final class PaletteSceneView: UIView {
    var look: ThemeLook? {
        didSet {
            apply()
        }
    }

    private var styleChange: (any UITraitChangeRegistration)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        observeStyle()
        apply()
    }

    func apply() {
        guard let scene = window?.windowScene else {
            return
        }

        switch look {
        case nil:
            scene.traitOverrides.remove(PaletteTrait.self)
            scene.traitOverrides.remove(UITraitUserInterfaceStyle.self)
        case let .fixed(palette):
            let style: UIUserInterfaceStyle = palette.isLight ? .light : .dark
            scene.traitOverrides[PaletteTrait.self] = palette
            scene.traitOverrides.userInterfaceStyle = style
        case let .system(light, dark):
            let style = scene.screen.traitCollection.userInterfaceStyle
            let palette = style == .dark ? dark : light
            scene.traitOverrides.remove(UITraitUserInterfaceStyle.self)
            scene.traitOverrides[PaletteTrait.self] = palette
        }
    }

    func observeStyle() {
        guard styleChange == nil else {
            return
        }

        styleChange = registerForTraitChanges(
            [UITraitUserInterfaceStyle.self]
        ) { (view: PaletteSceneView, _) in
            view.apply()
        }
    }
}
