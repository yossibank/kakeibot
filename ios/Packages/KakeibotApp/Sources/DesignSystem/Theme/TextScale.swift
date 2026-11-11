import SwiftUI

public enum TextScale {
    public static let floor = 0.8

    public static func fitting(
        available: CGFloat,
        needed: CGFloat,
        floor: Double = floor
    ) -> Double {
        guard
            needed > 0,
            available.isFinite
        else {
            return 1
        }

        let ratio = Double(available / needed * 100).rounded(.down) / 100

        return min(max(ratio, floor), 1)
    }
}

public extension EnvironmentValues {
    @Entry var sharedTextScale = 1.0
}

extension EnvironmentValues {
    @Entry var groupTextScale = 1.0
    @Entry var textScaleEpoch = 0
}
