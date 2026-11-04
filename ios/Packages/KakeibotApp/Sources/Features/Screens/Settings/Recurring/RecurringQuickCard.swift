import Core
import DesignSystem
import SwiftUI

struct RecurringQuickCard: View {
    @Bindable var model: RecurringEditModel

    @Environment(\.themeStyle.corner) private var corner

    let onOpen: (RecurringEditSheet.Panel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                onOpen(model.isCardBill ? .closing : .amount)
            } label: {
                ZStack(alignment: .trailing) {
                    if model.isCardBill {
                        Text("カードの利用分")
                            .displayFont(.headline, weight: .bold)
                            .foregroundStyle(Palette.accentStrong)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(maxWidth: .infinity)
                    } else {
                        SettingsKeypadValue(model.amount)
                            .frame(maxWidth: .infinity)
                    }

                    EditBadge(size: 16)
                }
                .frame(minHeight: 56)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if model.type != .transfer {
                section("カテゴリ") {
                    categoryGrid
                }
            }

            section(model.walletTitle) {
                walletGrid
            }

            if model.type == .transfer {
                section(RecurringEditModel.destinationTitle) {
                    destinationGrid
                }
            }

            section("繰り返し", value: scheduleText) {
                scheduleChooser
            }
        }
        .padding(16)
        .background(SettingsTile.cardFill.opacity(0.7), in: shape)
        .overlay {
            shape
                .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }
}

private extension RecurringQuickCard {
    var categoryGrid: some View {
        let shown = Self.limited(model.categories, selected: model.categoryId, count: 10)

        return VStack(spacing: 8) {
            SettingsTileGrid(items: shown, columns: 5, spacing: 4) { category in
                SettingsCategoryTile(
                    category: category,
                    icon: model.icon(for: category),
                    isSelected: model.categoryId == category.id
                ) {
                    model.select(category: category.id)
                }
            }

            if model.categories.count > shown.count {
                moreButton("すべてのカテゴリ") {
                    onOpen(.category)
                }
            }
        }
    }

    var walletGrid: some View {
        let shown = Self.limited(model.wallets, selected: model.walletId, count: 4)

        return VStack(alignment: .leading, spacing: 12) {
            SettingsTileGrid(items: shown, columns: 2, spacing: 8) { wallet in
                SettingsWalletTile(
                    wallet: wallet,
                    icon: model.icon(for: wallet),
                    isSelected: model.walletId == wallet.id
                ) {
                    model.walletId = wallet.id
                }
            }

            if model.wallets.count > shown.count {
                moreButton("すべての口座") {
                    onOpen(.wallet)
                }
            }

            if model.billRecurring != nil {
                SettingsBillShiftPicker(shift: $model.billShift, dates: model.billDates)
            }
        }
    }

    var destinationGrid: some View {
        let shown = Self.limited(model.wallets, selected: model.toWalletId, count: 4)

        return VStack(spacing: 8) {
            SettingsTileGrid(items: shown, columns: 2, spacing: 8) { wallet in
                SettingsWalletTile(
                    wallet: wallet,
                    icon: model.icon(for: wallet),
                    isSelected: model.toWalletId == wallet.id
                ) {
                    model.toWalletId = wallet.id
                }
            }

            if model.wallets.count > shown.count {
                moreButton("すべての口座") {
                    onOpen(.destination)
                }
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

            RecurringDayStrip(day: model.day) { day in
                model.day = day
            }
        }
        .animation(.snappy, value: model.frequency)
    }

    func section(
        _ title: String,
        value: String? = nil,
        @ViewBuilder content: () -> some View
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                SettingsSectionTitle(title)

                Spacer(minLength: 8)

                if let value {
                    Text(value)
                        .textFont(.footnote)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accentStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.trailing, 8)
                }
            }

            content()
        }
    }

    func moreButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .textFont(.footnote)

                Image(systemName: "chevron.right")
                    .sansFont(.small)
            }
            .foregroundStyle(Palette.accent)
            .frame(maxWidth: .infinity, minHeight: 32)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
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

    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(20))
    }

    var scheduleText: String {
        RecurringText.schedule(model.frequency, month: model.month, day: model.day)
    }

    static func limited<Item: Identifiable>(
        _ items: [Item],
        selected: Item.ID?,
        count: Int
    ) -> [Item] {
        let head = Array(items.prefix(count))

        guard
            let selected,
            !head.contains(where: { $0.id == selected }),
            let item = items.first(where: { $0.id == selected })
        else {
            return head
        }

        return head.dropLast() + [item]
    }
}
