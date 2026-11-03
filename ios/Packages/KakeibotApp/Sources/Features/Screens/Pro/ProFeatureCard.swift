import DesignSystem
import SwiftUI

struct ProFeatureCard: View {
    let feature: ProFeature

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: feature.systemImage)
                    .sansFont(.small, weight: .medium)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 38, height: 38)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.name)
                        .textFont(.caption2, weight: .semibold)
                        .tracking(1)
                        .foregroundStyle(Palette.accent)

                    Text(feature.headline)
                        .displayFont(.body, weight: .semibold)
                        .foregroundStyle(Palette.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            FeatureArt(kind: feature.art)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(feature.points, id: \.self) { point in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Palette.accent)

                        Text(point)
                            .foregroundStyle(Palette.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .textFont(.footnote)
                }
            }
        }
        .padding(16)
        .card()
    }
}
