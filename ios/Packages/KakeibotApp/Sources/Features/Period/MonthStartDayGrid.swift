import Core
import DesignSystem
import SwiftUI

struct MonthStartDayGrid: View {
    let selection: MonthStartDay
    let onSelect: (MonthStartDay) -> Void

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 8) {
            ForEach(MonthStartDay.allDays, id: \.day) { day in
                dayButton(day)
            }
        }
    }
}

private extension MonthStartDayGrid {
    func dayButton(_ day: MonthStartDay) -> some View {
        let isSelected = selection == day
        let textColor = isSelected ? Palette.backgroundBottom : Palette.text
        let fill = isSelected ? Palette.accent : Palette.accent.opacity(.faint)
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)

        return Button {
            onSelect(day)
        } label: {
            Text(Self.title(for: day))
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, minHeight: 42)
                .background(fill, in: Circle())
                .overlay {
                    Circle()
                        .stroke(stroke, lineWidth: 1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}

private extension MonthStartDayGrid {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

    static func title(for day: MonthStartDay) -> String {
        day.isLastDay ? "末日" : "\(day.day)"
    }
}
