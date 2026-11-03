import Core
import DesignSystem
import SwiftUI

struct FeatureArtMiniHome: View {
    var body: some View {
        FeatureArtCanvas(width: Self.width, height: Self.height) {
            screen
        }
    }
}

private extension FeatureArtMiniHome {
    static let width: CGFloat = 300
    static let height: CGFloat = 536
}

private extension FeatureArtMiniHome {
    var screen: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("11月")
                    .displayFont(.body)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                Text("11/1〜11/30")
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 0)

                ForEach(["bell", "gearshape"], id: \.self) { symbol in
                    Image(systemName: symbol)
                        .sansFont(.body, weight: .light)
                        .foregroundStyle(Palette.accent)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Circle()
                                .stroke(Palette.outline, lineWidth: 1)
                        }
                }
            }

            dialCard

            recentCard

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
    }

    var dialCard: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                HalfDial(progress: 0.62)

                VStack(spacing: 2) {
                    Text("今月あといくら")
                        .textFont(size: .caption)
                        .tracking(4)
                        .foregroundStyle(Palette.accent)

                    Text(AmountText.text(FeatureArtSample.remaining))
                        .displayFont(.title, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                }
                .padding(.horizontal, 28)
            }
            .frame(width: 236)

            Text("予算 \(AmountText.text(200_000))")
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            HStack(spacing: 0) {
                summary("今日の支出", amount: FeatureArtSample.todayExpense)
                summary("今月の支出", amount: FeatureArtSample.monthExpense)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .card()
    }

    var recentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近の記録")
                .textFont(.caption)
                .tracking(3)
                .foregroundStyle(Palette.accent)

            ForEach(FeatureArtSample.items, id: \.self) { item in
                HStack(spacing: 8) {
                    Circle()
                        .fill(Palette.accent.opacity(.subtle))
                        .frame(width: 26, height: 26)

                    Text(item.name)
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.text)

                    Spacer(minLength: 0)

                    Text(AmountText.text(item.amount))
                        .displayFont(.body, weight: .medium)
                        .monospacedDigit()
                        .foregroundStyle(Palette.text)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    func summary(
        _ title: String,
        amount: Int
    ) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .textFont(size: .caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(amount))
                .displayFont(.body, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
        .frame(maxWidth: .infinity)
    }
}
