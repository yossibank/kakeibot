import Core
import DesignSystem
import SwiftUI

struct RecurringDayStrip: View {
    let day: Int
    let onSelect: (Int) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(MonthStartDay.allDays, id: \.day) { choice in
                        dayButton(choice)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .onAppear {
                proxy.scrollTo(day, anchor: .center)
            }
            .onChange(of: day) { _, day in
                withAnimation(.snappy) {
                    proxy.scrollTo(day, anchor: .center)
                }
            }
        }
    }
}

private extension RecurringDayStrip {
    static let size: CGFloat = 44

    func dayButton(_ choice: MonthStartDay) -> some View {
        let isSelected = choice.day == day
        let textColor = isSelected ? Palette.backgroundBottom : Palette.text
        let fill = isSelected ? Palette.accent : Palette.accent.opacity(.faint)
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)
        let title = choice.isLastDay ? "末日" : "\(choice.day)"

        return Button {
            onSelect(choice.day)
        } label: {
            Text(title)
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 4)
                .frame(width: Self.size, height: Self.size)
                .background(fill, in: Circle())
                .overlay {
                    Circle()
                        .stroke(stroke, lineWidth: 1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .id(choice.day)
        .animation(.snappy(duration: 0.2), value: isSelected)
    }
}
