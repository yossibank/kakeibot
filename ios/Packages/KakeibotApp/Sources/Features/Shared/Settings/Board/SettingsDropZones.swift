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
    static let reach: CGFloat = 40

    func isOverHide(
        _ location: CGPoint,
        from origin: CGPoint
    ) -> Bool {
        let area = CGRect(
            x: hide.minX,
            y: hide.minY - Self.reach,
            width: hide.width,
            height: hide.height + Self.reach
        )

        return area.contains(Self.global(location, from: origin))
    }

    func isOverShow(
        _ location: CGPoint,
        from origin: CGPoint
    ) -> Bool {
        let area = CGRect(
            x: show.minX,
            y: show.minY,
            width: show.width,
            height: show.height + Self.reach
        )

        return area.contains(Self.global(location, from: origin))
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
