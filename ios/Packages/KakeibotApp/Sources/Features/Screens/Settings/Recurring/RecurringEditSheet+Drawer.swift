import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecurringEditSheet {
    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            amountKeypad

        case .start:
            MonthCalendar(
                selection: Bindable(model.state).fields.schedule.startDate,
                today: model.input.today
            )

        case .end:
            endChooser

        case .holiday:
            holidayChooser

        case .closing:
            closingChooser

        case .fee:
            feeKeypad

        case .count:
            countKeypad

        case .remind:
            remindChooser
        }
    }
}

private extension RecurringEditSheet {
    var amountKeypad: some View {
        VStack(spacing: 12) {
            SettingsKeypadAmount(model.output.amount)

            Keypad(calculator: model.state.submodels.amount) {
                closePanel()
            } onKey: { key in
                model.state.press(key)
            }
        }
    }

    var feeKeypad: some View {
        VStack(spacing: 12) {
            SettingsKeypadAmount(model.output.fee)

            FeeChoiceRow(
                choices: FeeChoiceRow.defaultChoices,
                selection: model.output.fee
            ) { amount in
                model.state.setFee(amount)
            }

            Keypad(calculator: model.state.submodels.fee) {
                closePanel()
            } onKey: { key in
                model.state.pressFee(key)
            }
        }
    }

    var countKeypad: some View {
        VStack(spacing: 12) {
            countChoices

            countValue

            Keypad(calculator: model.state.repayment.countCalculator) {
                closePanel()
            } onKey: { key in
                model.pressCount(key)
            }
        }
    }

    var countValue: some View {
        VStack(spacing: 4) {
            Text("\(model.state.repayment.countCalculator.amount) 回")
                .displayFont(.largeTitle, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .contentTransition(.numericText())
                .animation(.snappy, value: model.state.repayment.countCalculator.amount)

            Text(model.output.scheduledEndDate
                .map { "終わり \(RecurringText.date($0))" } ?? "回数を入れると、終わりの日が決まります")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
        }
    }

    @ViewBuilder
    var countChoices: some View {
        if let plan = model.output.autoPlan,
           let owed = model.output.loanOwed {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    SettingsChoice("残高から自動", isSelected: model.output.usesAutoCount) {
                        model.state.useAutoCount()
                        model.prepareCount()
                    }

                    SettingsChoice("決めない", isSelected: model.output.scheduledEndDate == nil) {
                        model.setEnd(nil)
                        closePanel()
                    }
                }

                Text(
                    "残高 \(Yen.text(owed)) ÷ \(Yen.text(model.output.amount)) で \(plan.count) 回。端数は最後の回に足します"
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
                SettingsChoice("終わりなし", isSelected: model.output.scheduledEndDate == nil) {
                    model.setEnd(nil)
                    closePanel()
                }

                SettingsChoice("今日で終える", isSelected: isEndingToday) {
                    model.setEnd(model.input.today)
                    closePanel()
                }
            }

            MonthCalendar(selection: endBinding, today: model.input.today)
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
                        isSelected: model.state.fields.schedule.holidayShift == shift
                    ) {
                        model.state.fields.schedule.choose(shift)
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

            SettingsChoice(
                RecurringText.closingDay(nil),
                isSelected: model.state.fields.schedule.closingDay == nil
            ) {
                model.state.fields.schedule.closingDay = nil
                closePanel()
            }

            MonthStartDayGrid(selection: closingDaySelection) { day in
                model.state.fields.schedule.closingDay = day.day
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
                    isSelected: model.state.fields.schedule.remindDaysBefore == days
                ) {
                    model.state.fields.schedule.remindDaysBefore = days
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
        model.state.fields.schedule.closingDay.flatMap { MonthStartDay($0) }
    }

    var isEndingToday: Bool {
        model.output.scheduledEndDate == model.input.today
    }

    var endBinding: Binding<LocalDate> {
        Binding {
            model.output.scheduledEndDate ?? model.state.fields.schedule.startDate
        } set: { date in
            model.setEnd(date)
        }
    }
}
