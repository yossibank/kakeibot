import DesignSystem
import SwiftUI

struct RecordsSheetPlaceholder: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .sansFont(.title, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 64, height: 64)
                .background(Palette.lit.opacity(.subtle), in: Circle())

            VStack(spacing: 8) {
                Text(title)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Text(message)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
            }
            .multilineTextAlignment(.center)

            PrimaryButton(actionTitle, action: action)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }
}
