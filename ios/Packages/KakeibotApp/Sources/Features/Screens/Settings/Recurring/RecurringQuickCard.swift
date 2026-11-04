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
                    text: model.isCardBill ? "カードの利用分" : nil
                ) {
                    onOpen(model.isCardBill ? .closing : .amount)
                }
            }

            if model.type != .transfer {
                SettingsFormSection("カテゴリ") {
                    categoryGrid
                }
            }

            SettingsFormSection(model.walletTitle) {
                walletGrid
            }

            if model.type == .transfer {
                SettingsFormSection(RecurringEditModel.destinationTitle) {
                    destinationGrid
                }
            }

            SettingsFormSection("繰り返し", value: scheduleText) {
                scheduleChooser
            }
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
                rows: 2,
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
            rows: 2,
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

    var scheduleText: String {
        RecurringText.schedule(model.frequency, month: model.month, day: model.day)
    }

    var scheduleDay: MonthStartDay {
        MonthStartDay(model.day) ?? .first
    }
}
