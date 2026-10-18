import Core
import DesignSystem
import Store
import SwiftUI

public struct MonthStartDayView: View {
    @State private var model: MonthStartDayModel

    @Environment(\.dismiss) private var dismiss

    public init(model: MonthStartDayModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: 18) {
            header

            Text("給料日に合わせると、その日から次の給料日の前の日までを 1 か月として数えます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 18) {
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
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.selection, trigger: model.startDay)
        .task {
            await model.load()
        }
    }
}

private extension MonthStartDayView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("月の始まり")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
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
