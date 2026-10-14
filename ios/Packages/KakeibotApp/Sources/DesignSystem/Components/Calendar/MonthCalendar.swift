import Core
import SwiftUI

public struct MonthCalendar: View {
    @Binding var selection: LocalDate

    @State private var month: YearMonth
    @State private var movesForward = true

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
                ForEach(
                    Weekday.week(startingOn: weekStart),
                    id: \.self
                ) { weekday in
                    Text(weekday.shortName)
                        .font(.caption2)
                        .foregroundStyle(Self.headerColor(for: weekday))
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
            }

            VStack(spacing: 6) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    HStack(spacing: 0) {
                        ForEach(
                            Array(week.enumerated()),
                            id: \.offset
                        ) { _, date in
                            cell(for: date)
                        }
                    }
                }
            }
            .id(month)
            .transition(.push(from: movesForward ? .trailing : .leading))
            .contentShape(.rect)
            .simultaneousGesture(swipe)
        }
        .clipped()
    }
}

private extension MonthCalendar {
    func monthButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        months: Int
    ) -> some View {
        Button {
            move(months: months)
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
            let holiday = Holiday.name(of: date)

            Button {
                selection = date
            } label: {
                VStack(spacing: 1) {
                    Text(String(date.day))
                        .font(.system(size: 17, weight: weight, design: .serif))
                        .foregroundStyle(foreground(for: date))
                        .frame(width: 32, height: 32)
                        .background(
                            isSelected ? Palette.gold : Color.clear,
                            in: Circle()
                        )
                        .overlay(Circle().stroke(ring, lineWidth: 1))

                    Text(holiday ?? "")
                        .font(.system(size: 8))
                        .foregroundStyle(Palette.holiday)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(height: 10)
                }
                .opacity(date > today && !isSelected ? 0.5 : 1)
                .frame(maxWidth: .infinity, minHeight: Self.cellHeight)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Self.label(for: date, holiday: holiday))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            Color.clear
                .frame(height: Self.cellHeight)
                .frame(maxWidth: .infinity)
        }
    }
}

private extension MonthCalendar {
    var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let width = value.translation.width

                guard
                    abs(width) > Self.swipeDistance,
                    abs(width) > abs(value.translation.height) else {
                    return
                }

                move(months: width < 0 ? 1 : -1)
            }
    }

    var weeks: [[LocalDate?]] {
        let weeks = month.weeks(startingOn: weekStart)
        let blank = [LocalDate?](repeating: nil, count: 7)
        let missing = max(Self.rowCount - weeks.count, 0)
        return weeks + Array(repeating: blank, count: missing)
    }

    var monthTitle: String {
        "\(month.year)年 \(month.month)月"
    }

    static let rowCount = 6
    static let swipeDistance: CGFloat = 50
    static let cellHeight: CGFloat = 46

    static func label(
        for date: LocalDate,
        holiday: String?
    ) -> String {
        guard let holiday else {
            return "\(date.day)日"
        }

        return "\(date.day)日 \(holiday)"
    }

    static func headerColor(for weekday: Weekday) -> Color {
        color(for: weekday) ?? Palette.mist
    }

    static func color(for weekday: Weekday) -> Color? {
        switch weekday {
        case .sunday: Palette.holiday
        case .saturday: Palette.saturday
        default: nil
        }
    }

    func move(months: Int) {
        movesForward = months > 0

        withAnimation(.snappy) {
            month = month.adding(months: months)
        }
    }

    func foreground(for date: LocalDate) -> Color {
        if date == selection {
            return Palette.nightBottom
        }

        if Holiday.contains(date) {
            return Palette.holiday
        }

        return Self.color(for: date.weekday) ?? Palette.ink
    }
}

#Preview {
    @Previewable @State var selection = LocalDate(Date(), in: .current)

    MonthCalendar(selection: $selection, today: LocalDate(Date(), in: .current))
        .padding()
        .background(Palette.night)
}
