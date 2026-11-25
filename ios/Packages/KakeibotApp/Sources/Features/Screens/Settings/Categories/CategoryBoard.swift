import Core
import DesignSystem
import FeatureModels
import SwiftUI

@MainActor
struct CategoryBoard {
    let parts: ScreenParts
    let kind: EntryCategory.Kind
}

extension CategoryBoard: SettingsBoardSpec {
    typealias Destination = CategoryListModel.Destination
    typealias Editor = CategoryEditSheet

    var title: String {
        "カテゴリ"
    }

    var hiddenTitle: String {
        "非表示のカテゴリ"
    }

    var deleteHiddenTitle: String {
        "非表示のカテゴリをまとめて削除しますか"
    }

    var deleteHiddenMessage: String {
        "記録があるカテゴリは残ります。使っている固定費・テンプレート・予算・タグも消えます"
    }

    var grid: SettingsBoardGrid {
        SettingsBoardGrid(columns: 4, itemHeight: 78, spacing: 8)
    }

    var space: String {
        "CategoryBoard"
    }

    var liftScale: CGFloat {
        1.1
    }

    func header(in model: CategoryListModel) -> some View {
        CapsulePicker(selection: Bindable(model.state).kind, options: Self.kindOptions)
    }

    func tile(
        _ item: EntryCategory,
        in model: CategoryListModel,
        isHidden: Bool
    ) -> some View {
        CategoryTileFace(
            icon: model.output.icon(for: item),
            name: item.name,
            isHidden: isHidden
        )
    }

    func editModel(for destination: Destination) -> CategoryEditModel {
        switch destination {
        case let .new(kind): CategoryEditModel(parts: parts, kind: kind)
        case let .edit(kind, id): CategoryEditModel(
                parts: parts,
                kind: kind,
                editing: id
            )
        }
    }

    func makeModel() -> CategoryListModel {
        CategoryListModel(parts: parts, kind: kind)
    }

    func intro(
        hint: SettingsFold,
        in _: CategoryListModel
    ) -> SettingsIntroCard {
        SettingsIntroCard(
            systemImage: "tag",
            headline: ("支出と収入を", "分けて振り返れます"),
            notes: [
                .init("arrow.left.arrow.right", "下で支出と収入を切り替えます"),
                .init("number", "開くと、タグで細かく分けられます"),
                .arrange
            ],
            hint: hint
        )
    }

    func emptyNote(in _: CategoryListModel) -> (systemImage: String, text: String) {
        ("tag", "カテゴリを足すと、ここに並びます")
    }

    func addTitle(in model: CategoryListModel) -> String {
        model.state.kind == .income ? "収入のカテゴリを追加" : "支出のカテゴリを追加"
    }

    func newDestination(in model: CategoryListModel) -> Destination {
        .new(model.state.kind)
    }

    func destination(editing item: EntryCategory) -> Destination {
        .edit(item.kind, item.id)
    }

    func itemID(of destination: Destination) -> EntryCategory.ID? {
        guard case let .edit(_, id) = destination else {
            return nil
        }

        return id
    }
}

private extension CategoryBoard {
    static var kindOptions: [CapsulePicker<EntryCategory.Kind>.Option] {
        [
            .init("支出", value: .expense),
            .init("収入", value: .income)
        ]
    }
}
