import Core
import DesignSystem
import FeatureModels
import SwiftUI

private extension ReviewClosingView {
    enum DayMark {
        case recorded
        case noSpend
        case empty
    }
}

extension ReviewClosingView {
    var streakCard: some View {
        let streak = content.streak

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ReviewReportLabel(title: "記録のつづき")

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .sansFont(.micro, weight: .bold)

                    Text("最長 \(streak.longest) 日")
                        .textFont(.caption2, weight: .bold)
                }
                .foregroundStyle(Palette.cardBottom)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Palette.gold, in: Capsule())
                .fixedSize()
            }

            Text("\(streak.days.count) 日 記録しました")
                .displayFont(.headline, weight: .bold)
                .foregroundStyle(Palette.text)

            if content.scale != .year {
                calendar

                legend
            }

            streakTrio
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(cornerRadius: 24)
    }
}

private extension ReviewClosingView {
    var streakTrio: some View {
        let streak = content.streak

        return HStack(spacing: 0) {
            trioItem(
                "calendar",
                value: "\(streak.days.count)",
                unit: "日",
                title: "記録した日"
            )

            Divider()

            trioItem(
                "square.and.pencil",
                value: "\(streak.count)",
                unit: "件",
                title: "\(name)の記録"
            )

            Divider()

            trioItem(
                "rosette",
                value: "\(content.continuing)",
                unit: periodsUnit,
                title: "続けている"
            )
        }
        .padding(.top, 12)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Palette.line)
                .frame(height: 1)
        }
    }

    var calendar: some View {
        let weekdays = Weekday.week(startingOn: content.weekStart)

        return Grid(horizontalSpacing: 0, verticalSpacing: 4) {
            GridRow {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday.shortName)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(Array(calendarWeeks.enumerated()), id: \.offset) { _, week in
                GridRow {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                        if let day {
                            dayCell(day)
                        } else {
                            Color.clear
                                .frame(height: Self.dayHeight)
                        }
                    }
                }
            }
        }
    }

    var legend: some View {
        HStack(spacing: 12) {
            legendItem(.recorded, title: "記録した日")
            legendItem(.noSpend, title: "支出なしの日")
            legendItem(.empty, title: "記録なし")
        }
    }

    func dayCell(_ day: LocalDate) -> some View {
        dayCircle(mark(on: day), size: Self.circleSize) {
            Text("\(day.day)")
                .sansFont(.micro, weight: .bold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.dayHeight)
    }

    func dayCircle(
        _ mark: DayMark,
        size: CGFloat,
        @ViewBuilder label: () -> some View
    ) -> some View {
        label()
            .frame(width: size, height: size)
            .foregroundStyle(Self.textColor(of: mark))
            .background {
                switch mark {
                case .recorded:
                    Circle()
                        .fill(Self.recordedFill)
                        .shadow(color: Palette.accent.opacity(.muted), radius: 3, y: 2)

                case .noSpend:
                    Circle()
                        .fill(Palette.accent.opacity(.subtle))
                        .overlay {
                            Circle()
                                .strokeBorder(Palette.accent, lineWidth: 1.5)
                        }

                case .empty:
                    Circle()
                        .strokeBorder(Palette.line, style: .dashed)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if mark == .noSpend,
                   size >= Self.circleSize {
                    Image(systemName: "checkmark")
                        .sansFont(.micro, weight: .black)
                        .imageScale(.small)
                        .foregroundStyle(Palette.cardBottom)
                        .frame(width: 12, height: 12)
                        .background(Palette.accent, in: Circle())
                        .offset(x: 2, y: 2)
                }
            }
    }

    func legendItem(
        _ mark: DayMark,
        title: String
    ) -> some View {
        HStack(spacing: 4) {
            dayCircle(mark, size: 12) {
                Color.clear
            }

            Text(title)
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    func trioItem(
        _ systemImage: String,
        value: String,
        unit: String,
        title: String
    ) -> some View {
        VStack(spacing: 2) {
            Image(systemName: systemImage)
                .sansFont(.small, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .padding(.bottom, 2)

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

private extension ReviewClosingView {
    static let dayHeight: CGFloat = 32
    static let circleSize: CGFloat = 28

    static var recordedFill: RadialGradient {
        RadialGradient(
            colors: [Palette.accentDeep, Palette.accent],
            center: .topLeading,
            startRadius: 0,
            endRadius: 32
        )
    }

    var calendarWeeks: [[LocalDate?]] {
        let weekdays = Weekday.week(startingOn: content.weekStart)
        let start = content.range.lowerBound
        let blanks = weekdays.firstIndex(of: start.weekday) ?? 0
        let days = (0..<totalDays).map { start.adding(days: $0) }
        let cells: [LocalDate?] = Array(repeating: nil, count: blanks) + days

        return stride(from: 0, to: cells.count, by: 7).map { index in
            let week = Array(cells[index..<min(index + 7, cells.count)])
            return week + Array(repeating: nil, count: 7 - week.count)
        }
    }

    static func textColor(of mark: DayMark) -> Color {
        switch mark {
        case .recorded: Palette.cardBottom
        case .noSpend: Palette.accent
        case .empty: Palette.subtext
        }
    }

    func mark(on day: LocalDate) -> DayMark {
        let streak = content.streak

        if streak.noSpendDays.contains(day) {
            return .noSpend
        }

        return streak.days.contains(day) ? .recorded : .empty
    }
}
