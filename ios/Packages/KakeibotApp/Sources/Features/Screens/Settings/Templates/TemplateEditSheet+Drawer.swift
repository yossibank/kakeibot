import Core
import DesignSystem
import Store
import SwiftUI

extension TemplateEditSheet {
    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            VStack(spacing: 12) {
                Keypad(calculator: model.calculator) {
                    closePanel()
                } onKey: { key in
                    model.press(key)
                }
            }

        case .category:
            SettingsTileGrid(items: model.categories, columns: 5, spacing: 4) { category in
                SettingsCategoryTile(
                    category: category,
                    icon: model.icon(for: category),
                    isSelected: model.categoryId == category.id
                ) {
                    model.categoryId = category.id
                    closePanel()
                }
            }
            .padding(.bottom, 8)

        case .tag:
            tagChooser
                .padding(.bottom, 8)

        case .wallet:
            SettingsTileGrid(items: model.wallets, columns: 3, spacing: 8) { wallet in
                SettingsWalletTile(
                    wallet: wallet,
                    icon: model.icon(for: wallet),
                    isSelected: model.walletId == wallet.id
                ) {
                    model.walletId = wallet.id
                    closePanel()
                }
            }
            .padding(.bottom, 8)

        case .memo:
            EmptyView()
        }
    }
}

private extension TemplateEditSheet {
    @ViewBuilder
    var tagChooser: some View {
        if model.tags.isEmpty {
            SettingsCaption("このカテゴリにタグはありません。カテゴリの編集で足せます")
                .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        } else {
            TagLine(tagItems, selection: model.tagId) { id in
                model.toggleTag(id)
            }
        }
    }
}

private extension TemplateEditSheet {
    var tagItems: [TagLine<EntryTag.ID>.Item] {
        model.tags.map { TagLine.Item(id: $0.id, name: $0.name) }
    }
}
