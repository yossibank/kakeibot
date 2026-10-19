import SwiftUI

struct SettingsDropZones: Equatable {
    var hide: CGRect = .zero
    var show: CGRect = .zero
}

extension SettingsDropZones {
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
        hiding: SettingsHideHover.State?,
        showing: Bool?
    ) -> some View {
        overlay(alignment: .bottom) {
            if let hiding {
                SettingsHideZone(state: hiding, height: 64)
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .global)
                    } action: { frame in
                        zones.wrappedValue.hide = frame
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if let showing {
                SettingsShowZone(isTargeted: showing)
                    .frame(height: 64)
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .global)
                    } action: { frame in
                        zones.wrappedValue.show = frame
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sensoryFeedback(.impact(weight: .heavy), trigger: hiding) { _, new in
            new == .armed
        }
    }
}
