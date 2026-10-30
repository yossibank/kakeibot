import Core
import DesignSystem
import SwiftUI

struct EntryDateSheet: View {
    @Bindable var model: EntryModel

    @Environment(\.dismiss) private var dismiss

    let today: LocalDate

    var body: some View {
        FittedSheet {
            VStack(alignment: .leading, spacing: 16) {
                Text("日付")
                    .textFont(.headline)
                    .foregroundStyle(Palette.accentStrong)

                HStack(spacing: 8) {
                    ForEach(Self.quickDays, id: \.offset) { quickDay in
                        quickButton(quickDay)
                    }
                }

                MonthCalendar(
                    selection: dateBinding,
                    today: today,
                    weekStart: model.weekStart
                )
            }
        }
    }
}

private extension EntryDateSheet {
    func quickButton(_ quickDay: QuickDay) -> some View {
        let date = today.adding(days: quickDay.offset)

        return ChipButton(
            quickDay.title,
            isSelected: model.date == date,
            size: .large
        ) {
            dateBinding.wrappedValue = date
        }
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
            get: {
                model.date
            },
            set: { date in
                model.date = date
                dismiss()
            }
        )
    }
}
