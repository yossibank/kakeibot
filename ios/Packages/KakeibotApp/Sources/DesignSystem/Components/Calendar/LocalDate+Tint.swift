import Core
import SwiftUI

public extension LocalDate {
    var tint: Color? {
        Holiday.contains(self) ? Palette.holiday : weekday.tint
    }
}
