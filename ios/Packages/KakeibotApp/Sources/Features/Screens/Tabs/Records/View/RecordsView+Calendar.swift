import Core
import DesignSystem
import SwiftUI

extension RecordsView {
    var calendar: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(Weekday.week(startingOn: model.weekStart), id: \.self) { weekday in
                    Text(weekday.shortName)
                        .textFont(.caption2)
                        .foregroundStyle(weekday.tint ?? Palette.subtext)
                        .frame(maxWidth: .infinity, minHeight: 22)
                }
            }

            let peak = isCalendarWide ? model.days.map(\.expenseTotal).max() ?? 0 : 0

            ForEach(Array(model.weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        calendarCell(date, peak: peak)
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .card()
    }

    var shownDayCard: some View {
        let date = model.shownDate
        let day = model.day(on: date)

        return VStack(spacing: 0) {
            dayHeader(date, day: day)

            if let day {
                ForEach(model.rows(for: day)) { row in
                    recordRow(row)

                    itemList(row)
                }
            }

            adjustmentList(on: date)

            let upcoming = model.upcomingRecurrings(on: date)

            if !upcoming.isEmpty {
                upcomingList(upcoming, on: date)
            } else if day == nil,
                      model.list != nil {
                Text("この日の記録はありません")
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 12)
            }

            HStack(spacing: 0) {
                dayButton("この日に記録する", systemImage: "plus") {
                    onAddEntry(date)
                }

                if model.canMarkNoSpend(on: date) {
                    let isMarked = model.noSpendDays.contains(date)
                    let title = isMarked ? "支出なしの印を外す" : "支出なしの日にする"
                    let image = isMarked ? "leaf.fill" : "leaf"

                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(width: 1, height: 24)

                    dayButton(title, systemImage: image) {
                        Task {
                            await model.toggleNoSpendDay(on: date)
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                Hairline(thickness: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .card()
    }
}

private extension RecordsView {
    @ViewBuilder
    func calendarCell(
        _ date: LocalDate?,
        peak: Int
    ) -> some View {
        if let date {
            let isShown = date == model.shownDate
            let day = model.day(on: date)
            let expense = day?.expenseTotal ?? 0
            let isNoSpend = model.noSpendDays.contains(date)
            let hasUpcoming = expense == 0
                && !isNoSpend
                && !model.upcomingRecurrings(on: date).isEmpty

            RecordsCalendarCell(
                day: date.day,
                dayColor: dayColor(date, isShown: isShown),
                isShown: isShown,
                isToday: date == model.today,
                isDimmed: date > model.today && !isShown,
                stamp: model.stampIcon(on: date),
                expense: expense,
                income: day?.incomeTotal ?? 0,
                isNoSpend: isNoSpend,
                hasUpcoming: hasUpcoming,
                heat: Self.heat(of: expense, peak: peak)
            ) {
                model.selectedDate = date
            }
            .equatable()
        } else {
            Color.clear
                .frame(maxWidth: .infinity, minHeight: 66)
        }
    }

    func dayButton(
        _ title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .textFont(.footnote)
                .foregroundStyle(Palette.accent)
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    static func heat(
        of expense: Int,
        peak: Int
    ) -> Double {
        guard peak > 0, expense > 0 else {
            return 0
        }

        return (Double(expense) / Double(peak)).squareRoot()
    }
}

private extension RecordsView {
    func dayColor(
        _ date: LocalDate,
        isShown: Bool
    ) -> Color {
        if isShown {
            return Palette.backgroundBottom
        }

        return date.tint ?? Palette.text
    }
}
