import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct RecurringQuickCard: View {
    @Bindable var model: RecurringEditModel

    let onOpen: (RecurringEditSheet.Panel) -> Void

    var body: some View {
        SettingsFormCard {
            SettingsFormSection("金額") {
                SettingsAmountButton(
                    amount: model.output.amount,
                    text: model.output.isCardBill ? "カードの利用分" : nil,
                    isEmpty: !model.output.isCardBill && model.output.amount == 0
                ) {
                    onOpen(model.output.isCardBill ? .closing : .amount)
                }
            }

            if model.state.type != .transfer {
                SettingsFormSection("カテゴリ") {
                    categoryGrid
                }
            }

            SettingsFormSection(
                model.output.walletTitle,
                value: model.output.selectedWallet?.name,
                valueIcon: model.output.selectedWallet.flatMap(model.output.icon(for:))
            ) {
                walletGrid
            }

            if model.state.type == .transfer {
                SettingsFormSection(
                    RecurringEditModel.destinationTitle,
                    value: model.output.selectedDestination?.name,
                    valueIcon: model.output.selectedDestination.flatMap(model.output.icon(for:))
                ) {
                    destinationGrid
                }
            }

            schedule
        }
    }
}

private extension RecurringQuickCard {
    var categoryGrid: some View {
        SettingsPagedGrid(
            items: model.output.categories,
            selected: model.state.categoryId,
            columns: 5,
            rows: 2,
            spacing: 4
        ) { category in
            SettingsCategoryTile(
                category: category,
                icon: model.output.icon(for: category),
                isSelected: model.state.categoryId == category.id
            ) {
                model.select(category: category.id)
            }
        }
    }

    var walletGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsPagedGrid(
                items: model.output.wallets,
                selected: model.state.walletId,
                columns: 2,
                rows: 3,
                spacing: 8
            ) { wallet in
                SettingsWalletTile(
                    wallet: wallet,
                    icon: model.output.icon(for: wallet),
                    isSelected: model.state.walletId == wallet.id
                ) {
                    model.state.setWallet(wallet.id)
                }
            }

            if model.output.billRecurring != nil {
                SettingsBillShiftPicker(
                    shift: Bindable(model.state).fields.billShift,
                    dates: model.output.billDates
                )
            }
        }
    }

    var destinationGrid: some View {
        SettingsPagedGrid(
            items: model.output.wallets,
            selected: model.state.toWalletId,
            columns: 2,
            rows: 3,
            spacing: 8
        ) { wallet in
            SettingsWalletTile(
                wallet: wallet,
                icon: model.output.icon(for: wallet),
                isSelected: model.state.toWalletId == wallet.id
            ) {
                model.state.selectDestination(wallet.id)
            }
        }
    }

    var schedule: some View {
        VStack(spacing: 12) {
            scheduleHeader

            if model.state.schedule.isOpen {
                scheduleChooser
                    .transition(.opacity)
            }
        }
    }

    var scheduleHeader: some View {
        Button {
            withAnimation(.snappy) {
                model.state.schedule.isOpen.toggle()
            }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                SettingsSectionTitle("繰り返し")
                    .layoutPriority(1)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Text(RecurringText.schedule(
                        model.state.schedule.frequency,
                        month: model.state.schedule.month,
                        day: model.state.schedule.day
                    ))
                    .textFont(.footnote)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Image(systemName: "chevron.down")
                        .sansFont(.small)
                        .rotationEffect(.degrees(model.state.schedule.isOpen ? 180 : 0))
                }
                .foregroundStyle(Palette.accentStrong)
                .padding(.trailing, 8)
            }
            .frame(minHeight: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    var scheduleChooser: some View {
        VStack(spacing: 12) {
            CapsulePicker(
                selection: Bindable(model.state).schedule.frequency,
                options: Self.frequencyOptions
            )

            if model.state.schedule.frequency == .yearly {
                LazyVGrid(columns: Self.monthColumns, spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        SettingsChoice(
                            "\(month) 月",
                            isSelected: model.state.schedule.month == month
                        ) {
                            model.state.schedule.month = month
                        }
                    }
                }
                .transition(.opacity)
            }

            MonthStartDayGrid(selection: scheduleDay) { day in
                model.state.schedule.day = day.day
            }
        }
        .animation(.snappy, value: model.state.schedule.frequency)
    }
}

private extension RecurringQuickCard {
    static let frequencyOptions: [CapsulePicker<Recurring.Frequency>.Option] = [
        .init("毎月", value: .monthly),
        .init("毎年", value: .yearly)
    ]

    static let monthColumns = Array(
        repeating: GridItem(
            .flexible(),
            spacing: 8
        ),
        count: 4
    )

    var scheduleDay: MonthStartDay {
        MonthStartDay(model.state.schedule.day) ?? .first
    }
}
