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
                    periodCard

                    LazyVGrid(columns: Self.columns, spacing: 8) {
                        ForEach(MonthStartDay.allDays, id: \.day) { day in
                            dayButton(day)
                        }
                    }

                    Text("29〜31 日を選ぶと、その日がない月は月末から始まります")
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Palette.rose)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var periodCard: some View {
        VStack(spacing: 6) {
            Text("いまの期間")
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.gold)

            Text(model.periodText)
                .font(.system(size: 26, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
                .contentTransition(.numericText())

            Text("\(model.month.month)月として数えます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .card(cornerRadius: 22)
        .animation(.snappy, value: model.startDay)
    }

    func dayButton(_ day: MonthStartDay) -> some View {
        let isSelected = model.startDay == day
        let textColor = isSelected ? Palette.nightBottom : Palette.ink
        let fill = isSelected ? Palette.gold : Palette.gold.opacity(0.04)
        let stroke = isSelected ? Palette.gold : Palette.gold.opacity(0.2)

        return Button {
            Task {
                await model.choose(day)
            }
        } label: {
            Text(Self.title(for: day))
                .font(.system(size: 15, design: .serif))
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

private extension MonthStartDayView {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 7
    )

    static func title(for day: MonthStartDay) -> String {
        day.isLastDay ? "末日" : "\(day.day)"
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
