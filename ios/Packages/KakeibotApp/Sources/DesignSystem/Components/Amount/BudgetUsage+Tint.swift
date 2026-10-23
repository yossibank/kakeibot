import Core
import SwiftUI

public extension BudgetUsage {
    var tint: Color {
        if isOver {
            return Palette.rose
        }

        return isNearLimit ? Palette.amber : Palette.accent
    }

    var amountTint: Color {
        isOver || isNearLimit ? tint : Palette.accentStrong
    }
}
