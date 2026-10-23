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
        VStack(spacing: 20) {
            SettingsBackHeader("月の始まり")

            Text("給料日に合わせると、その日から次の給料日の前の日までを 1 か月として数えます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 20) {
                    PeriodCard(
                        periodText: model.periodText,
                        month: model.month
                    )

                    MonthStartDayGrid(selection: model.startDay) { day in
                        Task {
                            await model.choose(day)
                        }
                    }

                    Text("29〜31 日を選ぶと、その日がない月は月末から始まります")
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: model.startDay)
        .task {
            await model.load()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            MonthStartDayView(
                model: MonthStartDayModel(
                    database: database,
                    today: LocalDate(Date(), in: .current)
                )
            )
        }
    }
}
