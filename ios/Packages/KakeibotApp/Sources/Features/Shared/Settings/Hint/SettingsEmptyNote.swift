import DesignSystem
import SwiftUI

struct SettingsEmptyNote: View {
    let systemImage: String
    let text: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.title, weight: .ultraLight)
                .foregroundStyle(Palette.accent)

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}
