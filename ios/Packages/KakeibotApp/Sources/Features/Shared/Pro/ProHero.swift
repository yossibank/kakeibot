import DesignSystem
import SwiftUI

struct ProHero: View {
    let price: String?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Self.gold)
                .frame(width: 56, height: 56)
                .overlay {
                    Circle()
                        .stroke(Self.gold, lineWidth: 1)
                }

            VStack(spacing: 6) {
                Text("かけいぼっと Pro")
                    .displayFont(.title, weight: .medium)
                    .foregroundStyle(Self.gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Text("毎日の家計簿を、もっと手軽に、自分らしく")
                    .textFont(.caption)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                if let price {
                    Text(price)
                        .displayFont(.largeTitle, weight: .bold)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }

                Text("買い切り")
                    .textFont(.caption, weight: .semibold)
                    .tracking(2)
                    .foregroundStyle(Self.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Self.gold, in: .capsule)
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    promises
                }

                VStack(alignment: .leading, spacing: 6) {
                    promises
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity)
        .background(Self.night, in: .rect(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Self.gold, lineWidth: 1.2)
                .padding(5)
                .opacity(0.6)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Self.gold, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }
}

private extension ProHero {
    static let ink = Color(red: 0.12, green: 0.1, blue: 0.08)

    static let promiseTitles = [
        "ずっと使える",
        "家族も使える",
        "これからの機能も"
    ]

    static var gold: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.87, blue: 0.62),
                Color(red: 0.8, green: 0.62, blue: 0.32),
                Color(red: 0.98, green: 0.9, blue: 0.68)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var night: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.16, green: 0.14, blue: 0.12),
                Color(red: 0.05, green: 0.05, blue: 0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private extension ProHero {
    var promises: some View {
        ForEach(Self.promiseTitles, id: \.self) { title in
            Label(title, systemImage: "checkmark")
                .textFont(.caption2, weight: .semibold)
                .foregroundStyle(.white.opacity(0.9))
                .labelStyle(PromiseLabelStyle())
        }
    }
}

private struct PromiseLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .foregroundStyle(Color(red: 0.9, green: 0.76, blue: 0.48))

            configuration.title
                .lineLimit(1)
                .fixedSize()
        }
    }
}
