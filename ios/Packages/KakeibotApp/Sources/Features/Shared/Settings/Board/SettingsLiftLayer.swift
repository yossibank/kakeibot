import DesignSystem
import SwiftUI

extension View {
    func settingsLiftLayer<ID: Hashable>(
        _ drag: SettingsDrag<ID>,
        size: CGSize? = nil,
        scale: CGFloat,
        @ViewBuilder tile: @escaping (ID) -> some View
    ) -> some View {
        let layer = SettingsLiftLayer(
            drag: drag,
            size: size,
            scale: scale,
            tile: tile
        )

        return modifier(layer)
    }

    func settingsLiftFrame<ID: Hashable>(
        _ drag: SettingsDrag<ID>,
        _ frames: ReferenceWritableKeyPath<SettingsDrag<ID>, [ID: CGRect]>,
        id: ID,
        in space: String
    ) -> some View {
        onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(space))
        } action: { frame in
            drag[keyPath: frames][id] = frame
        }
    }
}

private struct SettingsLiftLayer<ID: Hashable, Tile: View>: ViewModifier {
    @State private var origin: CGPoint = .zero

    let drag: SettingsDrag<ID>
    let size: CGSize?
    let scale: CGFloat
    let tile: (ID) -> Tile

    func body(content: Content) -> some View {
        content
            .overlay {
                ZStack {
                    if let floating = drag.floating {
                        floatingTile(floating)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .onGeometryChange(for: CGPoint.self) { proxy in
                    proxy.frame(in: .global).origin
                } action: { origin in
                    self.origin = origin
                }
            }
    }
}

private extension SettingsLiftLayer {
    func floatingTile(_ floating: SettingsDrag<ID>.Floating) -> some View {
        let tileSize = floating.size ?? size ?? .zero
        let center = CGPoint(
            x: floating.center.x + drag.origin.x - origin.x,
            y: floating.center.y + drag.origin.y - origin.y
        )

        return tile(floating.id)
            .frame(width: tileSize.width, height: tileSize.height)
            .scaleEffect(scale)
            .shadow(color: Palette.shadow.opacity(0.5), radius: 16, y: 8)
            .position(center)
            .transition(.identity)
    }
}
