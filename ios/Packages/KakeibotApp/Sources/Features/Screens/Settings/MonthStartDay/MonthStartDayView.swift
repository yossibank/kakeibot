import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct MonthStartDayView: View {
    @State private var model: MonthStartDayModel
    @State private var hintFlag: SettingsScreenFlag

    public init(model: MonthStartDayModel) {
        let hintFlag = model.hintFlag()

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("月の始まり", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "calendar",
                headline: ("給料日に合わせて", "1 か月を数えられます"),
                notes: [
                    .init("arrow.right", "給料日から、次の給料日の前日までです"),
                    .init("calendar.badge.exclamationmark", "29〜31 日が無い月は、月末からです"),
                    .init("arrow.left.arrow.right", "土日・祝日は、平日にずらせます")
                ],
                flag: hintFlag
            )

            ScrollView {
                VStack(spacing: SettingsSpacing.section) {
                    PeriodCard(periodText: model.output.periodText, month: model.output.month)

                    MonthStartDayGrid(selection: model.input.startDay) { day in
                        Task {
                            await model.choose(day)
                        }
                    }

                    shiftSection
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .settingsScreen(errorNotice: Bindable(model.state).errorNotice)
        .haptic(.selection, trigger: model.input.startDay)
        .task {
            await model.load()
        }
    }
}

private extension MonthStartDayView {
    var shiftSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("土日・祝日のとき")
                .textFont(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.accent)

            HStack(spacing: 8) {
                ForEach(HolidayShift.allCases, id: \.self) { shift in
                    SettingsChoice(shift.title, isSelected: model.input.startDay.shift == shift) {
                        Task {
                            await model.choose(shift)
                        }
                    }
                }
            }

            Text(model.output.shiftNote)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .card()
        .animation(.snappy, value: model.output.shiftNote)
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        let today = LocalDate(Date(), in: .current)

        NavigationStack {
            MonthStartDayView(
                model: MonthStartDayModel(
                    parts: parts,
                    today: today
                )
            )
        }
    }
}
