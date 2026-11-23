import Core
import DesignSystem
import Store
import SwiftUI

@MainActor
struct StampBoard {
    let database: AppDatabase
}

extension StampBoard: SettingsBoardSpec {
    enum Destination: Hashable {
        case new
        case edit(ShelfIcon.ID)
    }

    var screen: SettingsScreen {
        .stamps
    }

    var title: String {
        "スタンプ"
    }

    var emptyNote: (systemImage: String, text: String) {
        ("seal", "スタンプを足すと、ここに並びます")
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
        StampTileFace(icon: model.icon(for: item), isHidden: isHidden)
    }

    func editor(
        for destination: Destination,
        onDelete: @escaping (Deletion) -> Void,
        onHide: @escaping () -> Void
    ) -> some View {
        StampEditSheet(model: editModel(for: destination), onDelete: onDelete, onHide: onHide)
    }

    func makeModel() -> StampListModel {
        StampListModel(database: database)
    }

    func intro(flag: SettingsScreenFlag) -> SettingsIntroCard {
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

    func addTitle(in _: StampListModel) -> String {
        "スタンプを追加"
    }

    func newDestination(in _: StampListModel) -> Destination {
        .new
    }

    func destination(editing item: ShelfIcon) -> Destination {
        .edit(item.id)
    }

    func itemID(of destination: Destination) -> ShelfIcon.ID? {
        guard case let .edit(id) = destination else {
            return nil
        }

        return id
    }
}

private extension StampBoard {
    func editModel(for destination: Destination) -> StampEditModel {
        switch destination {
        case .new:
            StampEditModel(database: database)

        case let .edit(id):
            StampEditModel(database: database, editing: id)
        }
    }
}
