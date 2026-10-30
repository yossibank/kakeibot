import DesignSystem
import SwiftUI

struct SyncIntroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "icloud")
                    .sansFont(.body, weight: .light)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Circle()
                            .stroke(Palette.outline, lineWidth: 0.8)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    Text("自分の iPhone・iPad で")

                    Text("同じ記録を使えます")
                }
                .displayFont(.body, weight: .medium)
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }

            Hairline()

            VStack(alignment: .leading, spacing: 12) {
                note("arrow.triangle.2.circlepath", "同じ Apple ID の端末どうしでそろいます")

                note("iphone.and.arrow.forward", "機種変更しても、記録が残ります")

                note("person.2", "家族とは、口座ごとに共有できます")

                note("lock", "記録は暗号化して iCloud に置きます")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

private extension SyncIntroCard {
    func note(
        _ systemImage: String,
        _ text: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .sansFont(.caption, weight: .medium)
                .foregroundStyle(Palette.accent)
                .frame(width: 22)

            Text(text)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

#Preview {
    SyncIntroCard()
        .padding()
        .background(Palette.background)
}
