import Core
import DesignSystem
import SwiftUI

struct MonthStartDayGrid: View {
    let selection: MonthStartDay?
    let onSelect: (MonthStartDay) -> Void

    var body: some View {
        Grid(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(Self.rows, id: \.self) { row in
                GridRow {
                    ForEach(row, id: \.day) { day in
                        dayButton(day)
                    }
                }
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
    static let rows: [[MonthStartDay]] = {
        let days = MonthStartDay.allDays

        return stride(from: 0, to: days.count, by: 7).map { start in
            Array(days[start..<min(start + 7, days.count)])
        }
    }()

    static func title(for day: MonthStartDay) -> String {
        day.isLastDay ? "末日" : "\(day.day)"
    }
}
