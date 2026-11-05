import Core
import DesignSystem
import SwiftUI

struct SettingsBillShiftPicker: View {
    @Binding var shift: Int

    let dates: [LocalDate]

    var body: some View {
        let titles = Recurring.billShiftTitles

        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("請求")

            HStack(spacing: 8) {
                ForEach(titles.indices, id: \.self) { index in
                    SettingsChoice(titles[index], isSelected: shift == index) {
                        shift = index
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)

            SettingsCaption(note)
        }
    }
}

private extension SettingsBillShiftPicker {
    static let relativeNotes = [
        "使った日の、いつもの引き落としに入れます",
        "使った日から 1 回あとの引き落としに回します",
        "使った日から 2 回あとの引き落としに回します"
    ]

    var note: String {
        guard dates.indices.contains(shift) else {
            return Self.relativeNotes[shift]
        }

        let bill = Recurring.billText(paidOn: dates[shift])
        return "次の記録は、\(bill)の引き落としに入れます"
    }
}
