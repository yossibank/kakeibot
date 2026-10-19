import SwiftUI

extension View {
    func settingsLiftPreview(
        at center: CGPoint?,
        in viewport: CGRect,
        @ViewBuilder content: () -> some View
    ) -> some View {
        overlay {
            if let center {
                let x = center.x - viewport.minX
                let y = center.y - viewport.minY

                content()
                    .shadow(color: .black.opacity(0.5), radius: 16, y: 8)
                    .position(x: x, y: y)
                    .allowsHitTesting(false)
            }
        }
    }
}
