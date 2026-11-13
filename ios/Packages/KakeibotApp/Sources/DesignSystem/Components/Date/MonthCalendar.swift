import Core
import SwiftUI

public struct MonthCalendar: View {
    @Binding var selection: LocalDate

    @State private var month: YearMonth
    @State private var movesForward = true

    let today: LocalDate
    let weekStart: Weekday
    let isCompact: Bool

    public init(
        selection: Binding<LocalDate>,
        today: LocalDate,
        weekStart: Weekday = .sunday,
        isCompact: Bool = false
    ) {
        _selection = selection
        _month = State(initialValue: selection.wrappedValue.yearMonth)

        self.today = today
        self.weekStart = weekStart
        self.isCompact = isCompact
    }

    public var body: some View {
        let weekdays = Weekday.week(startingOn: weekStart)
        let rows = Array(weeks.enumerated())
        let edge: Edge = movesForward ? .trailing : .leading

        VStack(spacing: 8) {
            HStack {
                monthButton(systemImage: "chevron.left", months: -1)

                Spacer()

                Text(monthTitle)
                    .displayFont(.headline, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)

                Spacer()

                monthButton(systemImage: "chevron.right", months: 1)
            }

            HStack(spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday.shortName)
                        .textFont(.caption2)
                        .foregroundStyle(Self.headerColor(for: weekday))
                        .frame(maxWidth: .infinity, minHeight: 24)
                }
            }

            VStack(spacing: rowSpacing) {
                ForEach(rows, id: \.offset) { _, week in
                    let days = Array(week.enumerated())

                    HStack(spacing: 0) {
                        ForEach(days, id: \.offset) { _, date in
                            cell(for: date)
                        }
                    }
                }
            }
            .id(month)
            .transition(.push(from: edge))
            .contentShape(.rect)
            .gesture(swipe)
        }
        .clipped()
    }
}

private extension MonthCalendar {
    func monthButton(
        systemImage: String,
        months: Int
    ) -> some View {
        Button {
            move(months: months)
        } label: {
            Image(systemName: systemImage)
                .sansFont(.small, weight: .semibold)
                .foregroundStyle(Palette.subtext)
                .frame(width: 44, height: 36)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func cell(for date: LocalDate?) -> some View {
        if let date {
            let isSelected = date == selection
            let weight: Font.Weight = isSelected ? .semibold : .regular
            let ring = date == today && !isSelected
                ? Palette.accent
                : Color.clear
            let fill = isSelected ? Palette.accent : Color.clear
            let opacity = date > today && !isSelected
                ? 0.5
                : 1
            let holiday = Holiday.name(of: date)

            Button {
                selection = date
            } label: {
                VStack(spacing: 1) {
                    Text(String(date.day))
                        .displayFont(.body, weight: weight)
                        .foregroundStyle(foreground(for: date))
                        .frame(width: dayWidth, height: dayWidth)
                        .background(fill, in: Circle())
                        .overlay(Circle().stroke(ring, lineWidth: 1))

                    Text(holiday ?? "")
                        .textFont(size: .micro)
                        .foregroundStyle(Palette.holiday)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(height: 10)
                }
                .opacity(opacity)
                .frame(maxWidth: .infinity, minHeight: cellHeight)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        } else {
            Color.clear
                .frame(height: cellHeight)
                .frame(maxWidth: .infinity)
        }
    }
}

private extension MonthCalendar {
    static let rowCount = 6
    static let swipeDistance: CGFloat = 50

    var cellHeight: CGFloat {
        isCompact ? 36 : 46
    }

    var dayWidth: CGFloat {
        isCompact ? 26 : 32
    }

    var rowSpacing: CGFloat {
        isCompact ? 2 : 8
    }

    var swipe: SwipeGesture {
        SwipeGesture { _ in } onEnd: { width in
            guard abs(width) > Self.swipeDistance else {
                return
            }

            let months = width < 0 ? 1 : -1

            move(months: months)
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

    static func headerColor(for weekday: Weekday) -> Color {
        weekday.tint ?? Palette.subtext
    }

    func move(months: Int) {
        movesForward = months > 0

        withAnimation(.snappy) {
            month = month.adding(months: months)
        }
    }

    func foreground(for date: LocalDate) -> Color {
        if date == selection {
            return Palette.backgroundBottom
        }

        return date.tint ?? Palette.text
    }
}

#Preview {
    @Previewable @State var selection = LocalDate(Date(), in: .current)

    let today = LocalDate(Date(), in: .current)

    MonthCalendar(selection: $selection, today: today)
        .padding()
        .background(Palette.background)
}
