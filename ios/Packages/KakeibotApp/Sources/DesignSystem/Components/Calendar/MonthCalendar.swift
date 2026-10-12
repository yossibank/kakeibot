import Core
import SwiftUI

public struct MonthCalendar: View {
    @Binding var selection: LocalDate

    @State private var month: YearMonth

    let today: LocalDate
    let weekStart: Weekday

    public init(
        selection: Binding<LocalDate>,
        today: LocalDate,
        weekStart: Weekday = .sunday
    ) {
        _selection = selection
        _month = State(initialValue: selection.wrappedValue.yearMonth)
        self.today = today
        self.weekStart = weekStart
    }

    public var body: some View {
        VStack(spacing: 6) {
            HStack {
                monthButton("前の月", systemImage: "chevron.left", months: -1)

                Spacer()

                Text(monthTitle)
                    .font(.system(size: 20, weight: .medium, design: .serif))
                    .foregroundStyle(Palette.champagne)

                Spacer()

                monthButton("次の月", systemImage: "chevron.right", months: 1)
            }

            HStack(spacing: 0) {
                ForEach(Weekday.week(startingOn: weekStart), id: \.self) { weekday in
                    Text(weekday.shortName)
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 0) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        cell(for: date)
                    }
                }
            }
        }
    }
}

private extension MonthCalendar {
    func monthButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        months: Int
    ) -> some View {
        Button {
            month = month.adding(months: months)
        } label: {
            Image(systemName: systemImage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.mist)
                .frame(width: 44, height: 36)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    func cell(for date: LocalDate?) -> some View {
        if let date {
            let isSelected = date == selection
            let weight: Font.Weight = isSelected ? .semibold : .regular
            let ring = date == today && !isSelected ? Palette.gold : Color.clear

            Button {
                selection = date
            } label: {
                Text(String(date.day))
                    .font(.system(size: 18, weight: weight, design: .serif))
                    .foregroundStyle(foreground(for: date))
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Palette.gold : Color.clear, in: Circle())
                    .overlay(Circle().stroke(ring, lineWidth: 1))
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            Color.clear
                .frame(height: 40)
                .frame(maxWidth: .infinity)
        }
    }
}

private extension MonthCalendar {
    var monthTitle: String {
        "\(month.year)年 \(month.month)月"
    }

    var weeks: [[LocalDate?]] {
        month.weeks(startingOn: weekStart)
    }

    func foreground(for date: LocalDate) -> Color {
        if date == selection {
            return Palette.nightBottom
        }

        return date > today ? Palette.dusk : Palette.ink
    }
}

#Preview {
    @Previewable @State var selection = LocalDate(Date(), in: .current)

    MonthCalendar(selection: $selection, today: LocalDate(Date(), in: .current))
        .padding()
        .background(Palette.night)
}
