import Core
import DesignSystem
import SwiftUI

extension ReviewClosingView {
    var streakCard: some View {
        let streak = content.streak

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ReviewReportLabel(title: "記録のつづき")

                Text("最長 \(streak.longest) 日")
                    .textFont(.caption2, weight: .bold)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Palette.accent.opacity(.subtle), in: Capsule())
                    .fixedSize()
            }

            Text("\(streak.days.count) 日 記録しました")
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)

            if content.scale == .month {
                calendar
            }

            HStack(spacing: 0) {
                trioItem("\(streak.days.count)", unit: "日", title: "記録した日")

                Divider()

                trioItem("\(streak.count)", unit: "件", title: "\(name)の記録")

                Divider()

                trioItem("\(content.continuing)", unit: periodsUnit, title: "続けている")
            }
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Palette.line)
                    .frame(height: 1)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }
}

private extension ReviewClosingView {
    var calendarDays: [LocalDate?] {
        let weekdays = Weekday.week(startingOn: content.weekStart)
        let start = content.range.lowerBound
        let blanks = weekdays.firstIndex(of: start.weekday) ?? 0
        let days = (0..<totalDays).map { start.adding(days: $0) }
        return Array(repeating: nil, count: blanks) + days
    }

    var calendar: some View {
        let weekdays = Weekday.week(startingOn: content.weekStart)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday.shortName)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }

            ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, day in
                if let day {
                    dayCell(day, column: index % 7)
                } else {
                    Color.clear
                        .frame(height: 28)
                }
            }
        }
    }

    func dayCell(
        _ day: LocalDate,
        column: Int
    ) -> some View {
        let days = content.streak.days
        let isOn = days.contains(day)
        let joinsLeft = isOn && column > 0 && days.contains(day.adding(days: -1))
        let joinsRight = isOn && column < 6 && days.contains(day.adding(days: 1))
        let band = Palette.accent.opacity(.soft)
        let leftBand = joinsLeft ? band : .clear
        let rightBand = joinsRight ? band : .clear
        let textColor = isOn ? Palette.backgroundBottom : Palette.subtext

        return ZStack {
            HStack(spacing: 0) {
                Rectangle()
                    .fill(leftBand)

                Rectangle()
                    .fill(rightBand)
            }
            .frame(height: 16)

            Text("\(day.day)")
                .sansFont(.micro, weight: .bold)
                .foregroundStyle(textColor)
                .frame(width: 24, height: 24)
                .background {
                    if isOn {
                        Circle()
                            .fill(Palette.gold)
                    } else {
                        Circle()
                            .strokeBorder(Palette.line)
                    }
                }
        }
        .frame(height: 28)
    }

    func trioItem(
        _ value: String,
        unit: String,
        title: String
    ) -> some View {
        VStack(spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .displayFont(.headline, weight: .bold)
                    .foregroundStyle(Palette.text)
                    .monospacedDigit()

                Text(unit)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)
            }

            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
