import Core
import DesignSystem
import Store
import SwiftUI

public struct MonthStartDayView: View {
    @State private var model: MonthStartDayModel

    public init(model: MonthStartDayModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("月の始まり")

            ScrollView {
                VStack(spacing: SettingsSpacing.section) {
                    SettingsIntroCard(
                        systemImage: "calendar",
                        headline: ("給料日に合わせて", "1 か月を数えられます"),
                        notes: [
                            .init("arrow.right", "給料日から、次の給料日の前日までです"),
                            .init("calendar.badge.exclamationmark", "29〜31 日が無い月は、月末からです"),
                            .init("arrow.left.arrow.right", "土日・祝日は、平日にずらせます")
                        ]
                    )

                    PeriodCard(periodText: model.periodText, month: model.month)

                    MonthStartDayGrid(selection: model.startDay) { day in
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
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.selection, trigger: model.startDay)
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
                    SettingsChoice(shift.title, isSelected: model.startDay.shift == shift) {
                        Task {
                            await model.choose(shift)
                        }
                    }
                }
            }

            Text(model.shiftNote)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .card()
        .animation(.snappy, value: model.shiftNote)
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let today = LocalDate(Date(), in: .current)

        NavigationStack {
            MonthStartDayView(
                model: MonthStartDayModel(
                    database: database,
                    today: today
                )
            )
        }
    }
}
