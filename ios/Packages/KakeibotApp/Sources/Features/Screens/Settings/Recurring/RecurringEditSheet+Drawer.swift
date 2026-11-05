import Core
import DesignSystem
import Store
import SwiftUI

extension RecurringEditSheet {
    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            VStack(spacing: 12) {
                SettingsKeypadValue(model.amount)

                Keypad(calculator: model.calculator) {
                    closePanel()
                } onKey: { key in
                    model.press(key)
                }
            }

        case .start:
            MonthCalendar(selection: $model.startDate, today: model.today)

        case .end:
            endChooser

        case .holiday:
            holidayChooser

        case .closing:
            closingChooser

        case .fee:
            VStack(spacing: 12) {
                SettingsKeypadValue(model.fee)

                FeeChoiceRow(choices: FeeChoiceRow.defaultChoices, selection: model.fee) { amount in
                    model.setFee(amount)
                }

                Keypad(calculator: model.feeCalculator) {
                    closePanel()
                } onKey: { key in
                    model.pressFee(key)
                }
            }

        case .count:
            VStack(spacing: 12) {
                countChoices

                countValue

                Keypad(calculator: model.countCalculator) {
                    closePanel()
                } onKey: { key in
                    model.pressCount(key)
                }
            }

        case .remind:
            remindChooser
        }
    }
}

private extension RecurringEditSheet {
    var countValue: some View {
        VStack(spacing: 4) {
            Text("\(model.countCalculator.amount) 回")
                .displayFont(.largeTitle, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .contentTransition(.numericText())
                .animation(.snappy, value: model.countCalculator.amount)

            Text(model.scheduledEndDate
                .map { "終わり \(RecurringText.date($0))" } ?? "回数を入れると、終わりの日が決まります")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
        }
    }

    @ViewBuilder
    var countChoices: some View {
        if let plan = model.autoPlan,
           let owed = model.loanOwed {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    SettingsChoice("残高から自動", isSelected: model.usesAutoCount) {
                        model.useAutoCount()
                        model.prepareCount()
                    }

                    SettingsChoice("決めない", isSelected: model.scheduledEndDate == nil) {
                        model.setEnd(nil)
                        closePanel()
                    }
                }

                Text(
                    "残高 \(AmountText.text(owed)) ÷ \(AmountText.text(model.amount)) で \(plan.count) 回。端数は最後の回に足します"
                )
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)
            }
        }
    }

    var endChooser: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                SettingsChoice("終わりなし", isSelected: model.scheduledEndDate == nil) {
                    model.setEnd(nil)
                    closePanel()
                }

                SettingsChoice("今日で終える", isSelected: isEndingToday) {
                    model.setEnd(model.today)
                    closePanel()
                }
            }

            MonthCalendar(selection: endBinding, today: model.today)
        }
    }

    var holidayChooser: some View {
        VStack(spacing: 12) {
            Text("土日・祝日・年末年始（12/31〜1/3）に当たったときに、日をずらします")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                ForEach(HolidayShift.allCases, id: \.self) { shift in
                    SettingsChoice(
                        shift.title,
                        isSelected: model.holidayShift == shift
                    ) {
                        model.choose(shift)
                        closePanel()
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    var closingChooser: some View {
        VStack(spacing: 12) {
            Text("締め日までのカードの利用分を、引き落とし日に振り替えます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            SettingsChoice(RecurringText.closingDay(nil), isSelected: model.closingDay == nil) {
                model.closingDay = nil
                closePanel()
            }

            MonthStartDayGrid(selection: closingDaySelection) { day in
                model.closingDay = day.day
                closePanel()
            }
        }
        .padding(.bottom, 8)
    }

    var remindChooser: some View {
        LazyVGrid(columns: Self.remindColumns, spacing: 8) {
            ForEach(RecurringEditModel.remindChoices, id: \.self) { days in
                SettingsChoice(
                    RecurringText.remind(days),
                    isSelected: model.remindDaysBefore == days
                ) {
                    model.remindDaysBefore = days
                    closePanel()
                }
            }
        }
        .padding(.bottom, 8)
    }
}

private extension RecurringEditSheet {
    static let remindColumns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: 8
        ),
        count: 3
    )

    var closingDaySelection: MonthStartDay? {
        model.closingDay.flatMap { MonthStartDay($0) }
    }

    var isEndingToday: Bool {
        model.scheduledEndDate == model.today
    }

    var endBinding: Binding<LocalDate> {
        Binding {
            model.scheduledEndDate ?? model.startDate
        } set: { date in
            model.setEnd(date)
        }
    }
}
