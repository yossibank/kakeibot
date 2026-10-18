import SwiftUI

extension View {
    @ViewBuilder
    func glass(
        tint: Color?,
        in shape: some Shape
    ) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.tint(tint).interactive(), in: shape)
        } else {
            background(.ultraThinMaterial, in: shape)
        }
    }
}
