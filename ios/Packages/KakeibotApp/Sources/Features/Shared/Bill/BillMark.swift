import DesignSystem
import SwiftUI

struct BillMark: View {
    let isOpen: Bool

    var body: some View {
        Circle()
            .fill(isOpen ? Palette.panel : Palette.accent)
            .overlay {
                if isOpen {
                    Circle()
                        .strokeBorder(Palette.accent, lineWidth: 2)
                }
            }
            .frame(width: 10, height: 10)
    }
}
