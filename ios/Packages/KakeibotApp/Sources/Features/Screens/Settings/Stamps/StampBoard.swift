import Core
import DesignSystem
import Store
import SwiftUI

@MainActor
struct StampBoard {
    let database: AppDatabase
}

extension StampBoard: SettingsBoardSpec {
    typealias Destination = SettingsBoardDestination<ShelfIcon.ID>
    typealias Editor = StampEditSheet

    var screen: SettingsScreen {
        .stamps
    }

    var title: String {
        "スタンプ"
    }

    var hiddenTitle: String {
        "非表示のスタンプ"
    }

    var deleteHiddenTitle: String {
        "非表示のスタンプをまとめて削除しますか"
    }

    var deleteHiddenMessage: String {
        "カレンダーに押したスタンプは残ります"
    }

    var grid: SettingsBoardGrid {
        SettingsBoardGrid(columns: 4, itemHeight: 78, spacing: 8)
    }

    var space: String {
        "StampBoard"
    }

    var liftScale: CGFloat {
        1.1
    }

    func tile(
        _ item: ShelfIcon,
        in model: StampListModel,
        isHidden: Bool
    ) -> some View {
        StampTileFace(icon: model.output.icon(for: item), isHidden: isHidden)
    }

    func editModel(for destination: Destination) -> StampEditModel {
        StampEditModel(database: database, editing: destination.editingID)
    }

    func intro(
        flag: SettingsScreenFlag,
        in _: StampListModel
    ) -> SettingsIntroCard {
        SettingsIntroCard(
            systemImage: "seal",
            headline: ("カレンダーに押して", "その日を残せます"),
            notes: [
                .init("hand.tap", "押すと、絵と名前を変えられます"),
                .arrange
            ],
            flag: flag
        )
    }

    func emptyNote(in _: StampListModel) -> (systemImage: String, text: String) {
        ("seal", "スタンプを足すと、ここに並びます")
    }
}
