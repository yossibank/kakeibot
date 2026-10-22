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

    func isOverHide(
        _ location: CGPoint,
        from origin: CGPoint
    ) -> Bool {
        hide.contains(Self.global(location, from: origin))
    }

    func isOverShow(
        _ location: CGPoint,
        from origin: CGPoint
    ) -> Bool {
        show.contains(Self.global(location, from: origin))
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
                let height = showing
                    ? SettingsDropZones.openHeight
                    : SettingsDropZones.showHeight

                SettingsShowZone(isTargeted: showing)
                    .frame(height: height)
                    .animation(.smooth(duration: 0.35), value: showing)
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
