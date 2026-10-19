import CoreGraphics

struct SettingsHiddenLift<ID: Hashable> {
    let id: ID
    let start: CGPoint
    var location: CGPoint
}

extension SettingsHiddenLift {
    var offset: CGSize {
        CGSize(
            width: location.x - start.x,
            height: location.y - start.y
        )
    }
}
