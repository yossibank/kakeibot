import Core
import DesignSystem
import FeatureModels
import SwiftUI

@MainActor
struct RewardRuleBoard {
    let parts: ScreenParts
}

extension RewardRuleBoard: SettingsBoardSpec {
    typealias Destination = SettingsBoardDestination<RewardRule.ID>
    typealias Editor = RewardRuleEditSheet

    var screen: SettingsScreen {
        .rewards
    }

    var title: String {
        "ごほうびの決まり"
    }

    var hiddenTitle: String {
        "非表示の決まり"
    }

    var deleteHiddenTitle: String {
        "非表示の決まりをまとめて削除しますか"
    }

    var deleteHiddenMessage: String {
        "貯めた記録があるものは残ります"
    }

    var grid: SettingsBoardGrid {
        SettingsBoardGrid(columns: 2, itemHeight: 156, spacing: 12)
    }

    var space: String {
        "RewardBoard"
    }

    var liftScale: CGFloat {
        1.1
    }

    func tile(
        _ item: RewardRule,
        in model: RewardRuleListModel,
        isHidden: Bool
    ) -> some View {
        RewardRuleTile(
            icon: model.output.icon(for: item),
            name: item.name,
            amount: item.amount,
            total: model.output.total(for: item),
            isHidden: isHidden
        )
    }

    func editModel(for destination: Destination) -> RewardRuleEditModel {
        RewardRuleEditModel(parts: parts, editing: destination.editingID)
    }

    func intro(
        flag: SettingsScreenFlag,
        in _: RewardRuleListModel
    ) -> SettingsIntroCard {
        SettingsIntroCard(
            systemImage: "gift",
            headline: ("我慢できた日に", "決めた額を貯めます"),
            notes: [
                .init("banknote", "口座の残高は変わりません"),
                .arrange
            ],
            flag: flag
        )
    }

    func emptyNote(in _: RewardRuleListModel) -> (systemImage: String, text: String) {
        ("gift", "ごほうびの決まりを足すと、ここに並びます")
    }
}
