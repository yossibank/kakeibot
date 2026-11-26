import SwiftUI

public struct TagLineMovingKey: PreferenceKey {
    public static let defaultValue = false

    public static func reduce(
        value: inout Bool,
        nextValue: () -> Bool
    ) {
        value = value || nextValue()
    }
}
