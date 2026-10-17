import Core
import SwiftUI

public extension Weekday {
    var tint: Color? {
        switch self {
        case .sunday: Palette.holiday
        case .saturday: Palette.saturday
        default: nil
        }
    }
}
