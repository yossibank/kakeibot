import Core
import DesignSystem
import SwiftUI

struct EntryDateSheet: View {
    @Bindable var model: EntryModel

    @Environment(\.dismiss) private var dismiss

    let today: LocalDate

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("日付")
                .font(.headline)
                .foregroundStyle(Palette.champagne)

            HStack(spacing: 8) {
                ForEach(Self.quickDays, id: \.offset) { quickDay in
                    quickButton(quickDay)
                }
            }

            MonthCalendar(selection: dateBinding, today: today)

            Spacer(minLength: 0)
        }
        .padding(20)
        .presentationDetents([.height(520), .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Palette.drawer)
        .preferredColorScheme(.dark)
    }
}

private extension EntryDateSheet {
    func quickButton(_ quickDay: QuickDay) -> some View {
        let date = today.adding(days: quickDay.offset)
        let isSelected = model.date == date

        return Button(quickDay.title) {
            dateBinding.wrappedValue = date
        }
        .font(.subheadline)
        .foregroundStyle(isSelected ? Palette.champagne : Palette.ink)
        .padding(.horizontal, 16)
        .frame(minHeight: 40)
        .background(isSelected ? Palette.gold.opacity(0.12) : Color.clear, in: Capsule())
        .overlay(Capsule().stroke(isSelected ? Palette.gold : Palette.line, lineWidth: 1))
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private extension EntryDateSheet {
    struct QuickDay {
        let title: String
        let offset: Int
    }

    static let quickDays = [
        QuickDay(title: "今日", offset: 0),
        QuickDay(title: "昨日", offset: -1),
        QuickDay(title: "おととい", offset: -2)
    ]

    var dateBinding: Binding<LocalDate> {
        Binding(
            get: { model.date },
            set: { date in
                model.date = date
                dismiss()
            }
        )
    }
}
