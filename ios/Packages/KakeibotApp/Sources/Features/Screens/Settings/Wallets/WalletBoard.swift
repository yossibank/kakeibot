import Core
import DesignSystem
import FeatureModels
import SwiftUI

@MainActor
struct WalletBoard {
    let parts: ScreenParts
}

extension WalletBoard: SettingsBoardSpec {
    typealias Destination = SettingsBoardDestination<Wallet.ID>
    typealias Editor = WalletEditSheet

    var title: String {
        "口座"
    }

    var hiddenTitle: String {
        "非表示の口座"
    }

    var deleteHiddenTitle: String {
        "非表示の口座をまとめて削除しますか"
    }

    var deleteHiddenMessage: String {
        "記録がある口座は残ります。使っている固定費・テンプレート・評価額も消えます"
    }

    var grid: SettingsBoardGrid {
        SettingsBoardGrid(columns: 1, itemHeight: WalletRowCard<WalletRowIcon>.height, spacing: 12)
    }

    var space: String {
        "WalletBoard"
    }

    var liftScale: CGFloat {
        1.03
    }

    var layout: SettingsBoardLayout {
        .swipeRows
    }

    func tile(
        _ item: Wallet,
        in model: WalletListModel,
        isHidden _: Bool
    ) -> some View {
        WalletRowCard(
            name: item.name,
            kind: item.kind,
            amount: model.balance(of: item),
            caption: item.kind.role.balanceLabel(model.output.balance(
                of: item,
                through: parts.clock.today
            )),
            isShared: model.output.isShared(item)
        ) {
            WalletRowIcon(icon: model.output.icon(for: item))
        }
    }

    func editModel(for destination: Destination) -> WalletEditModel {
        WalletEditModel(parts: parts, editing: destination.editingID)
    }

    func intro(
        hint: SettingsFold,
        in _: WalletListModel
    ) -> SettingsIntroCard {
        SettingsIntroCard(
            systemImage: "building.columns",
            headline: ("お金を置く所ごとに", "残高を分けて数えます"),
            notes: [
                .init("wallet.bifold", "現金・銀行・カードなどを分けて持てます"),
                .init("person.2", "ほかの人とは、口座ごとに共有できます"),
                .arrange,
                .swipeDelete
            ],
            hint: hint
        )
    }

    func emptyNote(in _: WalletListModel) -> (systemImage: String, text: String) {
        ("building.columns", "口座を追加すると、ここに並びます")
    }

    func scaleID(in model: WalletListModel) -> [Wallet]? {
        model.output.shown + model.output.hidden
    }

    func hideConfirmation(
        of item: Wallet,
        in model: WalletListModel
    ) -> SettingsConfirmation? {
        guard model.output.needsHideConfirmation(of: item) else {
            return nil
        }

        return .hidingWallet(balance: model.balance(of: item))
    }

    func deleteConfirmation(
        of item: Wallet,
        in model: WalletListModel
    ) -> SettingsConfirmation? {
        .deletingWallet(hasEntries: model.output.hasEntries(item))
    }
}
