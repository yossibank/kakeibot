import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct TemplateQuickCard: View {
    @Bindable var model: TemplateEditModel

    let onOpen: (TemplateEditSheet.Panel) -> Void

    var body: some View {
        SettingsFormCard {
            SettingsFormSection("金額") {
                VStack(alignment: .leading, spacing: 8) {
                    SettingsAmountButton(
                        amount: model.output.amount ?? 0,
                        text: model.output.amount == nil ? "毎回入れる" : nil,
                        isEmpty: (model.output.amount ?? 0) == 0
                    ) {
                        onOpen(.amount)
                    }

                    SettingsCaption("金額を空にすると、使うときに入れられます。")
                }
            }

            SettingsFormSection("カテゴリ") {
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
                        model.state.setCategory(category.id)
                    }
                }
            }

            SettingsFormSection(
                model.output.walletTitle,
                value: model.output.selectedWallet?.name,
                valueIcon: model.output.selectedWallet.flatMap(model.output.icon(for:))
            ) {
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
                        SettingsBillShiftPicker(shift: Bindable(model.state).billShift, dates: [])
                    }
                }
            }
        }
    }
}
