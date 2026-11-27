import Core
import DesignSystem
import FeatureModels
import SwiftUI

@MainActor
struct RecurringBoard {
    let model: RecurringListModel
    let parts: ScreenParts
}

extension RecurringBoard {
    init(
        parts: ScreenParts,
        today: LocalDate
    ) {
        self.init(
            model: RecurringListModel(parts: parts, today: today),
            parts: parts
        )
    }
}

private extension RecurringBoard {
    func totalCard(in model: RecurringListModel) -> some View {
        VStack(spacing: 4) {
            Text("今月の\(model.state.fields.type.name)")
                .textFont(.caption2)
                .tracking(2)
                .foregroundStyle(Palette.accent)

            AmountText(model.output.monthTotal, font: .size(.headline), color: Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .card()
    }
}

private extension RecurringBoard {
    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("振替", value: .transfer)
    ]

    func notes(in model: RecurringListModel) -> [SettingsIntroCard.Note] {
        let purpose: [SettingsIntroCard.Note] = [
            .init("calendar", "休日なら、前後の平日にずらせます"),
            .init("bell", "前もって通知で知らせられます")
        ]

        if model.output.rows.isEmpty {
            return purpose
        }

        return purpose + [
            .init("hand.draw", "長押しで並べ替え・止めて非表示にできます"),
            .swipeDelete
        ]
    }
}

extension RecurringBoard: SettingsBoardSpec {
    typealias Destination = RecurringListModel.Destination
    typealias Editor = RecurringEditSheet

    var title: String {
        "固定費"
    }

    var hiddenTitle: String {
        "非表示の固定費"
    }

    var deleteHiddenTitle: String {
        "非表示の固定費をまとめて削除しますか"
    }

    var deleteHiddenMessage: String {
        "これまでに作った記録は残ります"
    }

    var grid: SettingsBoardGrid {
        SettingsBoardGrid(columns: 1, itemHeight: RecurringRowCard.height, spacing: 12)
    }

    var space: String {
        "RecurringList"
    }

    var liftScale: CGFloat {
        1.03
    }

    var layout: SettingsBoardLayout {
        .swipeRows
    }

    var hideMessage: String {
        "止めて非表示にしました"
    }

    func header(in model: RecurringListModel) -> some View {
        CapsulePicker(selection: Bindable(model.state).fields.type, options: Self.typeOptions)
    }

    @ViewBuilder
    func lead(in model: RecurringListModel) -> some View {
        if !model.output.rows.isEmpty {
            totalCard(in: model)
        }
    }

    @ViewBuilder
    func tile(
        _ item: Recurring,
        in model: RecurringListModel,
        isHidden: Bool
    ) -> some View {
        if let row = model.output.row(for: item) {
            RecurringRowCard(row: row, isPaused: isHidden)
        }
    }

    func editModel(for destination: Destination) -> RecurringEditModel {
        switch destination {
        case let .new(type):
            RecurringEditModel(
                parts: parts,
                today: model.input.today,
                type: type,
                editing: nil
            )

        case let .edit(type, id):
            RecurringEditModel(
                parts: parts,
                today: model.input.today,
                type: type,
                editing: id
            )
        }
    }

    func makeModel() -> RecurringListModel {
        model
    }

    func intro(
        hint: SettingsFold,
        in model: RecurringListModel
    ) -> SettingsIntroCard {
        SettingsIntroCard(
            systemImage: "repeat",
            headline: ("決まった日の記録を", "ひとりでに入れます"),
            notes: notes(in: model),
            hint: hint
        )
    }

    func emptyNote(in model: RecurringListModel) -> (systemImage: String, text: String) {
        switch model.state.fields.type {
        case .expense: ("repeat", "家賃やサブスクなどを足すと、ここに並びます")
        case .income: ("repeat", "給料や年金などを足すと、ここに並びます")
        case .transfer: ("repeat", "カードの引き落としや積立などを足すと、ここに並びます")
        }
    }

    func addTitle(in model: RecurringListModel) -> String {
        "\(model.state.fields.type.name)の固定費を追加"
    }

    func scaleID(in model: RecurringListModel) -> [String?]? {
        (model.output.rows + model.output.hiddenRows).map(\.place)
    }

    func newDestination(in model: RecurringListModel) -> Destination {
        .new(model.state.fields.type)
    }

    func destination(editing item: Recurring) -> Destination {
        .edit(item.type, item.id)
    }

    func itemID(of destination: Destination) -> Recurring.ID? {
        guard case let .edit(_, id) = destination else {
            return nil
        }

        return id
    }

    func deleteConfirmation(
        of _: Recurring,
        in _: RecurringListModel
    ) -> SettingsConfirmation? {
        .delete(title: "この固定費を削除しますか", message: "これまでに作った記録は残ります")
    }
}
