import Core
import DesignSystem
import SwiftUI

struct WhatsNewUpcomingScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .day:
            day

        case .open:
            row(Self.recurrings[0])
                .padding(.horizontal, 8)
                .card(cornerRadius: 12)
                .padding(.horizontal, 4)
                .whatsNewTapped()

        case .captions:
            captions
        }
    }
}

extension WhatsNewUpcomingScene {
    enum Step: Hashable, Sendable {
        case captions
        case day
        case open
    }
}

private extension WhatsNewUpcomingScene {
    struct Recurring {
        let name: String
        let amount: Int
    }

    static let recurrings = [
        Recurring(name: "家賃", amount: 85000),
        Recurring(name: "スマホ", amount: 3000)
    ]

    var captions: some View {
        VStack(alignment: .leading, spacing: 4) {
            caption("これから")

            dayCard(title: "25日", weekday: "（水）", isToday: false)

            caption("これまで")

            dayCard(title: "17日", weekday: "（火）", isToday: true)
        }
        .padding(.horizontal, 8)
    }

    var day: some View {
        VStack(alignment: .leading, spacing: 4) {
            dayTitle("25日", weekday: "（水）", isToday: false)

            Hairline(thickness: 1)

            Text("予定の固定費")
                .textFont(size: .micro)
                .tracking(1)
                .foregroundStyle(Palette.hint)

            ForEach(Self.recurrings, id: \.name) { recurring in
                row(recurring)
            }
        }
        .padding(8)
        .card(cornerRadius: 12)
        .padding(.horizontal, 4)
    }

    func caption(_ title: String) -> some View {
        Text(title)
            .textFont(size: .micro, weight: .semibold)
            .tracking(2)
            .foregroundStyle(Palette.accent)
    }

    func dayCard(
        title: String,
        weekday: String,
        isToday: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            dayTitle(title, weekday: weekday, isToday: isToday)

            Capsule()
                .fill(Palette.hairline)
                .frame(width: 64, height: 3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .card(cornerRadius: 8)
    }

    func dayTitle(
        _ title: String,
        weekday: String,
        isToday: Bool
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text(title)
                .textFont(size: .small, weight: .semibold)
                .foregroundStyle(Palette.accentStrong)

            Text(weekday)
                .textFont(size: .micro)
                .foregroundStyle(Palette.subtext)

            if isToday {
                Text("今日")
                    .textFont(size: .micro, weight: .semibold)
                    .foregroundStyle(Palette.accent)
            }
        }
    }

    func row(_ recurring: Recurring) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "repeat")
                .foregroundStyle(Palette.hint)

            Text(recurring.name)
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 4)

            AmountText(recurring.amount, type: .expense, font: .size(.caption, weight: .medium))
                .opacity(0.6)

            Image(systemName: "chevron.right")
                .foregroundStyle(Palette.hint)
        }
        .textFont(size: .caption)
        .frame(height: 28)
    }
}
