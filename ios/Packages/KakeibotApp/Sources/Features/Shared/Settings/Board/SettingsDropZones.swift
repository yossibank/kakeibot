import DesignSystem
import SwiftUI

struct SettingsDropZones: Equatable {
    var hide: CGRect = .zero
    var show: CGRect = .zero
}

extension SettingsDropZones {
    static let hideHeight: CGFloat = 50
    static let showHeight: CGFloat = 64
    static let openHeight: CGFloat = 136
    static let labelHeight: CGFloat = 44

    var hideTop: CGFloat {
        hide.maxY - Self.hideHeight
    }

    func isOverHide(
        _ location: CGPoint,
        from origin: CGPoint
    ) -> Bool {
        let area = CGRect(
            x: hide.minX,
            y: hideTop,
            width: hide.width,
            height: Self.hideHeight
        )

        let point = Self.global(location, from: origin)

        return area.contains(point)
    }

    func isOverShow(
        _ location: CGPoint,
        from origin: CGPoint
    ) -> Bool {
        let area = CGRect(
            x: show.minX,
            y: show.minY,
            width: show.width,
            height: Self.showHeight
        )

        let point = Self.global(location, from: origin)

        return area.contains(point)
    }
}

private extension SettingsDropZones {
    static func global(
        _ location: CGPoint,
        from origin: CGPoint
    ) -> CGPoint {
        CGPoint(x: location.x + origin.x, y: location.y + origin.y)
    }
}

extension View {
    func settingsDropZones(
        _ zones: Binding<SettingsDropZones>,
        showing: Bool?
    ) -> some View {
        overlay(alignment: .top) {
            if let showing {
                SettingsShowZone(isTargeted: showing)
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .global)
                    } action: { frame in
                        zones.wrappedValue.show = frame
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

struct SettingsShowZone: View {
    let isTargeted: Bool

    var body: some View {
        SettingsZoneBox(
            isOn: isTargeted,
            closedHeight: SettingsDropZones.showHeight,
            tint: Palette.accent,
            offLabel: .init(
                systemImage: "eye",
                title: "ここに置くと表示に戻ります"
            ),
            onLabel: .init(
                systemImage: "eye",
                title: "離すと表示に戻ります"
            )
        )
    }
}
