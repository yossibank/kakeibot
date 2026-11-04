import Core
import DesignSystem
import SwiftUI

struct TemplateQuickCard: View {
    @Bindable var model: TemplateEditModel

    let onOpen: (TemplateEditSheet.Panel) -> Void

    var body: some View {
        SettingsFormCard {
            SettingsFormSection("金額") {
                VStack(alignment: .leading, spacing: 8) {
                    SettingsAmountButton(
                        amount: model.amount ?? 0,
                        text: model.amount == nil ? "毎回入れる" : nil
                    ) {
                        onOpen(.amount)
                    }

                    SettingsCaption("金額を空にすると、使うときに入れられます。")
                }
            }

            SettingsFormSection("カテゴリ") {
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
                        model.categoryId = category.id
                    }
                }
            }

            SettingsFormSection(model.walletTitle) {
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
                        SettingsBillShiftPicker(shift: $model.billShift, dates: [])
                    }
                }
            }
        }
    }
}
