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
    var dockArea: CGRect? {
        let zones = drag.zones
        let label = SettingsDropZones.labelHeight
        let open = SettingsDropZones.openHeight
        let top: CGFloat
        let zone: CGRect

        if drag.isOverHide {
            zone = zones.hide
            top = zone.maxY - open + label
        } else if drag.isOverShow {
            zone = zones.show
            top = zone.minY + label
        } else {
            return nil
        }

        return CGRect(
            x: zone.minX - origin.x + Self.dockInset,
            y: top - origin.y,
            width: zone.width - Self.dockInset * 2,
            height: open - label - Self.dockInset
        )
    }

    func floatingTile(_ floating: SettingsDrag<ID>.Floating) -> some View {
        let tileSize = floating.size ?? size ?? .zero
        let dock = dockArea
        let isDocked = dock != nil
        let tileScale = dock.map { fitScale(tileSize, in: $0) } ?? scale

        let natural = CGPoint(
            x: floating.center.x + drag.origin.x - origin.x,
            y: floating.center.y + drag.origin.y - origin.y
        )

        let center = dock.map { CGPoint(x: $0.midX, y: $0.midY) } ?? natural

        return tile(floating.id)
            .frame(width: tileSize.width, height: tileSize.height)
            .scaleEffect(tileScale)
            .shadow(color: Palette.shadow.opacity(0.5), radius: 16, y: 8)
            .position(center)
            .animation(.spring(duration: 0.4, bounce: 0.2), value: isDocked)
            .transition(.identity)
    }

    func fitScale(
        _ tileSize: CGSize,
        in area: CGRect
    ) -> CGFloat {
        guard
            tileSize.width > 0,
            tileSize.height > 0
        else {
            return scale
        }

        let width = area.width / tileSize.width
        let height = area.height / tileSize.height
        return min(scale, width, height)
    }
}

private extension SettingsLiftLayer {
    static var dockInset: CGFloat {
        10
    }
}
