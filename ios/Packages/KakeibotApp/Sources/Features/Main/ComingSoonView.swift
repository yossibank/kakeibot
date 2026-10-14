import DesignSystem
import SwiftUI

struct ComingSoonView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text("これから作る画面です")
        )
        .foregroundStyle(Palette.mist)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ComingSoonView(title: "振り返り", systemImage: "chart.pie")
}
