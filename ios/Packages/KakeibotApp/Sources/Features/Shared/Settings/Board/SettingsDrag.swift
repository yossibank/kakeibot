import Observation
import SwiftUI

@MainActor
@Observable
final class SettingsDrag<ID: Hashable> {
    var zones = SettingsDropZones()
    var origin: CGPoint = .zero
    var hiddenFrames: [ID: CGRect] = [:]
    var rowFrames: [ID: CGRect] = [:]

    let autoScroll = SettingsAutoScroll()

    private(set) var lift: Lift?
    private(set) var hiddenLift: HiddenLift?
    private(set) var isOverHide = false
    private(set) var isOverShow = false
    private(set) var liftCount = 0
    private(set) var showCount = 0
}

extension SettingsDrag {
    struct Lift {
        let id: ID
        var location: CGPoint
        var grab: CGSize?
    }

    struct HiddenLift {
        let id: ID
        let start: CGPoint
        var location: CGPoint
    }

    struct Floating {
        let id: ID
        let center: CGPoint
        let size: CGSize?
    }

    enum Drop {
        case hide(ID)
        case move
    }

    var isLifting: Bool {
        lift != nil || hiddenLift != nil
    }

    var floating: Floating? {
        if let lift {
            let row = rowFrames[lift.id]
            let center = CGPoint(
                x: row?.midX ?? liftedCenter.x,
                y: liftedCenter.y
            )

            return Floating(id: lift.id, center: center, size: row?.size)
        }

        guard
            let hiddenLift,
            let frame = hiddenFrames[hiddenLift.id]
        else {
            return nil
        }

        let center = CGPoint(
            x: frame.midX + hiddenLift.location.x - hiddenLift.start.x,
            y: frame.midY + hiddenLift.location.y - hiddenLift.start.y
        )

        return Floating(
            id: hiddenLift.id,
            center: center,
            size: frame.size
        )
    }

    var showZone: Bool? {
        hiddenLift == nil ? nil : isOverShow
    }

    var liftedCenter: CGPoint {
        guard let lift else {
            return .zero
        }

        let grab = lift.grab ?? .zero

        return CGPoint(
            x: lift.location.x + grab.width,
            y: lift.location.y + grab.height
        )
    }

    func isLifted(_ id: ID) -> Bool {
        lift?.id == id
    }

    func hiddenOffset(of id: ID) -> CGSize? {
        guard
            let hiddenLift,
            hiddenLift.id == id
        else {
            return nil
        }

        return CGSize(
            width: hiddenLift.location.x - hiddenLift.start.x,
            height: hiddenLift.location.y - hiddenLift.start.y
        )
    }

    func follow(
        _ id: ID,
        from start: CGPoint,
        to location: CGPoint,
        onScroll: @escaping (CGPoint) -> Void
    ) -> CGPoint? {
        if lift == nil {
            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: id, location: start)
            }

            liftCount += 1
        }

        guard var current = lift else {
            return nil
        }

        if current.grab == nil {
            current.grab = CGSize(
                width: current.location.x - location.x,
                height: current.location.y - location.y
            )
        }

        current.location = location
        lift = current
        isOverHide = zones.isOverHide(location, from: origin)

        autoScroll.follow(
            y: location.y + origin.y,
            bottom: zones.hide.isEmpty ? nil : zones.hide.minY
        ) { delta in
            onScroll(CGPoint(x: location.x, y: location.y + delta))
        }

        guard !isOverHide else {
            return nil
        }

        return liftedCenter
    }

    func drop() -> Drop? {
        autoScroll.stop()

        guard let lift else {
            return nil
        }

        let isHiding = isOverHide

        withAnimation(.snappy) {
            self.lift = nil
            isOverHide = false
        }

        return isHiding ? .hide(lift.id) : .move
    }

    func followHidden(
        _ id: ID,
        to location: CGPoint
    ) {
        if hiddenLift == nil {
            withAnimation(.snappy(duration: 0.2)) {
                hiddenLift = HiddenLift(
                    id: id,
                    start: location,
                    location: location
                )
            }

            liftCount += 1
        }

        hiddenLift?.location = location
        isOverShow = zones.isOverShow(location, from: origin)
    }

    func dropHidden() -> ID? {
        guard let hiddenLift else {
            return nil
        }

        let isShowing = isOverShow

        withAnimation(.snappy) {
            self.hiddenLift = nil
            isOverShow = false
        }

        guard isShowing else {
            return nil
        }

        showCount += 1
        return hiddenLift.id
    }
}
