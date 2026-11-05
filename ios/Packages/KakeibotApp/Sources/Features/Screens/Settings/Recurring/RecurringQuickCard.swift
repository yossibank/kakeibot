import Core
import DesignSystem
import SwiftUI

struct RecurringQuickCard: View {
    @Bindable var model: RecurringEditModel

    let onOpen: (RecurringEditSheet.Panel) -> Void

    var body: some View {
        SettingsFormCard {
            SettingsFormSection("金額") {
                SettingsAmountButton(
                    amount: model.amount,
                    text: model.isCardBill ? "カードの利用分" : nil,
                    isEmpty: !model.isCardBill && model.amount == 0
                ) {
                    onOpen(model.isCardBill ? .closing : .amount)
                }
            }

            if model.type != .transfer {
                SettingsFormSection("カテゴリ") {
                    categoryGrid
                }
            }

            SettingsFormSection(
                model.walletTitle,
                value: model.selectedWallet?.name,
                valueIcon: model.selectedWallet.flatMap(model.icon(for:))
            ) {
                walletGrid
            }

            if model.type == .transfer {
                SettingsFormSection(
                    RecurringEditModel.destinationTitle,
                    value: model.selectedDestination?.name,
                    valueIcon: model.selectedDestination.flatMap(model.icon(for:))
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
            items: model.categories,
            selected: model.categoryId,
            columns: 5,
            rows: 2,
            spacing: 4
        ) { category in
            SettingsCategoryTile(
                category: category,
                icon: model.icon(for: category),
                isSelected: model.categoryId == category.id
            ) {
                model.select(category: category.id)
            }
        }
    }

    var walletGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsPagedGrid(
                items: model.wallets,
                selected: model.walletId,
                columns: 2,
                rows: 3,
                spacing: 8
            ) { wallet in
                SettingsWalletTile(
                    wallet: wallet,
                    icon: model.icon(for: wallet),
                    isSelected: model.walletId == wallet.id
                ) {
                    model.walletId = wallet.id
                }
            }

            if model.billRecurring != nil {
                SettingsBillShiftPicker(shift: $model.billShift, dates: model.billDates)
            }
        }
    }

    var destinationGrid: some View {
        SettingsPagedGrid(
            items: model.wallets,
            selected: model.toWalletId,
            columns: 2,
            rows: 3,
            spacing: 8
        ) { wallet in
            SettingsWalletTile(
                wallet: wallet,
                icon: model.icon(for: wallet),
                isSelected: model.toWalletId == wallet.id
            ) {
                model.toWalletId = wallet.id
            }
        }
    }

    var schedule: some View {
        VStack(spacing: 12) {
            scheduleHeader

            if model.isScheduleOpen {
                scheduleChooser
                    .transition(.opacity)
            }
        }
    }

    var scheduleHeader: some View {
        Button {
            withAnimation(.snappy) {
                model.isScheduleOpen.toggle()
            }
        } label: {
            HStack(alignment: .firstTextBaseline) {
                SettingsSectionTitle("繰り返し")
                    .layoutPriority(1)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Text(RecurringText.schedule(
                        model.frequency,
                        month: model.month,
                        day: model.day
                    ))
                    .textFont(.footnote)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                    Image(systemName: "chevron.down")
                        .sansFont(.small)
                        .rotationEffect(.degrees(model.isScheduleOpen ? 180 : 0))
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
            CapsulePicker(selection: $model.frequency, options: Self.frequencyOptions)

            if model.frequency == .yearly {
                LazyVGrid(columns: Self.monthColumns, spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        SettingsChoice("\(month) 月", isSelected: model.month == month) {
                            model.month = month
                        }
                    }
                }
                .transition(.opacity)
            }

            MonthStartDayGrid(selection: scheduleDay) { day in
                model.day = day.day
            }
        }
        .animation(.snappy, value: model.frequency)
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
        MonthStartDay(model.day) ?? .first
    }
}
