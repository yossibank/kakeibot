import Core
import DesignSystem
import Store
import SwiftUI

public struct RewardRuleListView: View {
    @State var model: RewardRuleListModel

    @State private var drag = SettingsDrag<RewardRule.ID>()
    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var hiddenId: RewardRule.ID?
    @State private var deletion: Deletion?
    @State private var bulkDelete: SettingsBulkDelete?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    @State private var grid = Self.tiles

    private let database: AppDatabase

    public init(database: AppDatabase) {
        let hintFlag = SettingsScreenFlag.closedHint(.rewards, in: database)
        let hiddenList = SettingsScreenFlag.openHiddenList(.rewards, in: database)

        _model = State(initialValue: RewardRuleListModel(database: database))
        _hintFlag = State(initialValue: hintFlag)
        _hiddenList = State(initialValue: hiddenList)

        self.database = database
    }

    public var body: some View {
        SettingsBoardScreen(
            title: "ごほうびの決まり",
            hint: hintFlag,
            intro: SettingsIntroCard(
                systemImage: "gift",
                headline: ("我慢できた日に", "決めた額を貯めます"),
                notes: [
                    .init("banknote", "口座の残高は変わりません"),
                    .arrange
                ],
                flag: hintFlag
            ),
            emptyNote: .init(systemImage: "gift", text: "ごほうびの決まりを足すと、ここに並びます"),
            addTitle: "ごほうびの決まりを追加",
            space: Self.space,
            tileHeight: Self.tiles.itemHeight,
            liftScale: 1.1,
            controller: controller,
            errorNotice: $model.errorNotice
        ) {
            destination = .new
        } board: {
            board
        } hiddenSection: {
            hiddenSection
        } floatingTile: { id in
            floatingTile(id)
        }
        .navigationDestination(item: $destination) { destination in
            RewardRuleEditSheet(model: editModel(for: destination)) { deletion in
                self.deletion = deletion
            } onHide: {
                if case let .edit(id) = destination {
                    hiddenId = id
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.isSettingsEditPushed, true)
        }
        .settingsDeleteHiddenConfirmation(
            isPresented: $isConfirmingDeleteHidden,
            title: "非表示の決まりをまとめて削除しますか",
            message: "貯めた記録があるものは残ります"
        ) {
            controller.deleteHidden()
        }
        .task {
            await model.observe()
        }
    }
}

private extension RewardRuleListView {
    var board: some View {
        SettingsTileBoard(
            grid: $grid,
            controller: controller,
            space: Self.space
        ) { rule in
            tileFace(rule, isHidden: false)
        } onTap: { rule in
            destination = .edit(rule.id)
        }
    }

    var hiddenSection: some View {
        SettingsHiddenTiles(
            flag: hiddenList,
            title: "非表示の決まり",
            grid: grid,
            controller: controller,
            space: Self.space
        ) { rule in
            tileFace(rule, isHidden: true)
        } onTap: { rule in
            destination = .edit(rule.id)
        } onDeleteAll: {
            isConfirmingDeleteHidden = true
        }
    }

    func tileFace(
        _ rule: RewardRule,
        isHidden: Bool
    ) -> some View {
        RewardRuleTile(
            icon: model.icon(for: rule),
            name: rule.name,
            amount: rule.amount,
            total: model.total(for: rule),
            isHidden: isHidden
        )
        .contentShape(.rect)
    }

    @ViewBuilder
    func floatingTile(_ id: RewardRule.ID) -> some View {
        if let rule = (model.shown + model.hidden).first(where: { $0.id == id }) {
            tileFace(rule, isHidden: false)
        }
    }
}

private extension RewardRuleListView {
    enum Destination: Hashable {
        case new
        case edit(RewardRule.ID)
    }

    nonisolated static let space = "RewardBoard"

    static let tiles = SettingsBoardGrid(columns: 2, itemHeight: 156, spacing: 12)

    var controller: SettingsBoardController<RewardRuleListModel> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: grid,
            hiddenId: $hiddenId,
            deletion: $deletion,
            bulkDelete: $bulkDelete
        )
    }

    func editModel(for destination: Destination) -> RewardRuleEditModel {
        switch destination {
        case .new:
            RewardRuleEditModel(database: database)

        case let .edit(id):
            RewardRuleEditModel(database: database, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            RewardRuleListView(database: database)
        }
    }
}
