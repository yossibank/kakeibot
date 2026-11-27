import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecordsView {
    var calendar: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                ForEach(Weekday.week(startingOn: model.input.weekStart), id: \.self) { weekday in
                    Text(weekday.shortName)
                        .textFont(.caption2)
                        .foregroundStyle(weekday.tint ?? Palette.subtext)
                        .frame(maxWidth: .infinity, minHeight: 22)
                }
            }

            let peak = isCalendarWide ? model.output.days.map(\.expenseTotal).max() ?? 0 : 0

            ForEach(Array(model.output.weeks.enumerated()), id: \.offset) { _, week in
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
        let date = model.output.shownDate
        let day = model.output.day(on: date)

        return VStack(spacing: 0) {
            dayHeader(date, day: day)

            if let day {
                ForEach(model.output.rows(for: day)) { row in
                    recordRow(row)

                    itemList(row)
                }
            }

            adjustmentList(on: date)

            let upcoming = model.output.upcomingRecurrings(on: date)
            let isEmptyDay = day == nil && model.input.list.isLoaded

            if !upcoming.isEmpty {
                upcomingList(upcoming, on: date)
            } else if isEmptyDay {
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

                if model.output.canMarkNoSpend(on: date) {
                    let isMarked = model.input.noSpendDays.contains(date)
                    let title = isMarked ? "支出なしの印を外す" : "支出なしの日にする"
                    let image = isMarked ? "leaf.fill" : "leaf"

                    Rectangle()
                        .fill(Palette.hairline)
                        .frame(width: 1, height: 24)

                    dayButton(title, systemImage: image) {
                        model.perform {
                            await $0.toggleNoSpendDay(on: date)
                        }
                    }
                }
            }
            .topHairline()
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
            let isShown = date == model.output.shownDate
            let day = model.output.day(on: date)
            let expense = day?.expenseTotal ?? 0
            let isNoSpend = model.input.noSpendDays.contains(date)
            let hasUpcoming = expense == 0
                && !isNoSpend
                && !model.output.upcomingRecurrings(on: date).isEmpty

            RecordsCalendarTile(
                day: date.day,
                dayColor: dayColor(date, isShown: isShown),
                isShown: isShown,
                isToday: date == model.input.today,
                isDimmed: date > model.input.today && !isShown,
                stamp: model.output.stampIcon(on: date),
                expense: expense,
                income: day?.incomeTotal ?? 0,
                isNoSpend: isNoSpend,
                hasUpcoming: hasUpcoming,
                heat: Self.heat(of: expense, peak: peak)
            ) {
                model.state.fields.selectedDate = date
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
}

private extension RecordsView {
    static func heat(
        of expense: Int,
        peak: Int
    ) -> Double {
        guard peak > 0, expense > 0 else {
            return 0
        }

        return (Double(expense) / Double(peak)).squareRoot()
    }

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
