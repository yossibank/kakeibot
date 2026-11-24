import Core
import DesignSystem
import Store
import SwiftUI

@MainActor
struct TemplateBoard {
    let database: AppDatabase
}

extension TemplateBoard: SettingsBoardSpec {
    enum Destination: Hashable {
        case new(Entry.Kind)
        case edit(Entry.Kind, EntryTemplate.ID)
    }

    typealias Editor = TemplateEditSheet

    var screen: SettingsScreen {
        .templates
    }

    var title: String {
        "テンプレート"
    }

    var hiddenTitle: String {
        "非表示のテンプレート"
    }

    var deleteHiddenTitle: String {
        "非表示のテンプレートをまとめて削除しますか"
    }

    var deleteHiddenMessage: String {
        "テンプレートで記録したものは残ります"
    }

    var grid: SettingsBoardGrid {
        SettingsBoardGrid(columns: 1, itemHeight: TemplateRowCard.Fit.fill.height, spacing: 12)
    }

    var space: String {
        "TemplateBoard"
    }

    var liftScale: CGFloat {
        1.03
    }

    var layout: SettingsBoardLayout {
        .swipeCards
    }

    var scrollMargin: CGFloat {
        20
    }

    func header(in model: TemplateListModel) -> some View {
        CapsulePicker(selection: Bindable(model.state).type, options: Self.typeOptions)
    }

    func tile(
        _ item: EntryTemplate,
        in model: TemplateListModel,
        isHidden _: Bool
    ) -> some View {
        TemplateRowCard(
            icon: model.output.icon(for: item),
            name: item.name,
            detail: model.output.detail(for: item),
            amount: item.amount
        )
    }

    func editModel(for destination: Destination) -> TemplateEditModel {
        switch destination {
        case let .new(type):
            TemplateEditModel(database: database, type: type)

        case let .edit(type, id):
            TemplateEditModel(database: database, type: type, editing: id)
        }
    }

    func intro(
        flag: SettingsScreenFlag,
        in model: TemplateListModel
    ) -> SettingsIntroCard {
        SettingsIntroCard(
            systemImage: "rectangle.stack",
            headline: ("よく使う入力を", "1 回で記録できます"),
            notes: notes(in: model),
            flag: flag
        )
    }

    func emptyNote(in _: TemplateListModel) -> (systemImage: String, text: String) {
        ("rectangle.stack", "テンプレートを足すと、ここに並びます")
    }

    func addTitle(in model: TemplateListModel) -> String {
        let typeName = model.state.type == .income ? "収入" : "支出"
        return "\(typeName)のテンプレートを追加"
    }

    func newDestination(in model: TemplateListModel) -> Destination {
        .new(model.state.type)
    }

    func destination(editing item: EntryTemplate) -> Destination {
        .edit(item.type, item.id)
    }

    func itemID(of destination: Destination) -> EntryTemplate.ID? {
        guard case let .edit(_, id) = destination else {
            return nil
        }

        return id
    }

    func deleteConfirmation(
        of _: EntryTemplate,
        in _: TemplateListModel
    ) -> SettingsConfirmation? {
        .delete(
            title: "このテンプレートを削除しますか",
            message: "このテンプレートで記録したものは残ります"
        )
    }
}

private extension TemplateBoard {
    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    func notes(in model: TemplateListModel) -> [SettingsIntroCard.Note] {
        let purpose: [SettingsIntroCard.Note] = [
            .init("hand.tap", "金額を決めておくと、押すだけで記録します"),
            .init("apps.iphone", "ウィジェットからも記録できます")
        ]

        if model.output.shown.isEmpty {
            return purpose
        }

        return purpose + [
            .init("list.number", "この順でホームと入力シートに出ます"),
            .arrange,
            .swipeDelete
        ]
    }
}
