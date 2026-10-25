import SwiftUI

public extension View {
    func editBadge(
        size: CGFloat = 18,
        spacing: CGFloat = 8
    ) -> some View {
        overlay(alignment: .trailing) {
            EditBadge(size: size)
                .offset(x: size + spacing)
        }
    }
}
