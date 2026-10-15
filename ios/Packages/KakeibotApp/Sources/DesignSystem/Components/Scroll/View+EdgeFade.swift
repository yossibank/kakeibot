import SwiftUI

public extension View {
    func edgeFade(_ length: CGFloat = 20) -> some View {
        mask {
            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: length)

                Color.black

                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: length)
            }
        }
    }
}
