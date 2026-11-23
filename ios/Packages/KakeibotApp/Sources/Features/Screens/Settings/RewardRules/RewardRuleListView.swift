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

    @State private var grid = SettingsBoardGrid(
        columns: Self.columnCount,
        itemHeight: Self.tileHeight,
        spacing: Self.spacing
    )

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
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("ごほうびの決まり", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "gift",
                headline: ("我慢できた日に", "決めた額を貯めます"),
                notes: [
                    .init("banknote", "口座の残高は変わりません"),
                    .arrange
                ],
                flag: hintFlag
            )

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    if model.shown.isEmpty {
                        SettingsEmptyNote(
                            systemImage: "gift",
                            text: "ごほうびの決まりを足すと、ここに並びます"
                        )
                    }

                    board

                    if !model.hidden.isEmpty {
                        hiddenSection
                    }
                }
                .padding(.vertical, 8)
                .coordinateSpace(.named(Self.space))
                .onGeometryChange(for: CGPoint.self) { proxy in
                    proxy.frame(in: .global).origin
                } action: { origin in
                    drag.origin = origin
                }
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(drag.isLifting)
            .settingsAutoScroll(drag.autoScroll)
            .settingsDropZones($drag.zones, showing: drag.showZone)
            .settingsHideNotice($hiddenId) { id in
                controller.show(id)
            }
            .deletionNotice($deletion, note: bulkDelete?.note(for: deletion)) { deletion in
                controller.restore(deletion)
            }

            if drag.lift != nil {
                SettingsHideTarget(
                    zones: $drag.zones,
                    isArmed: drag.isOverHide
                )
            } else {
                AddButton("ごほうびの決まりを追加") {
                    destination = .new
                }
            }
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .settingsLiftLayer(
            drag,
            size: CGSize(width: grid.itemWidth, height: Self.tileHeight),
            scale: 1.1
        ) { id in
            floatingTile(id)
        }
        .errorBanner($model.errorNotice)
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.impact(weight: .medium), trigger: drag.liftCount)
        .haptic(.selection, trigger: model.movingOrder)
        .haptic(.success, trigger: drag.showCount)
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
        .confirmation(
            isPresented: $isConfirmingDeleteHidden,
            systemImage: "trash",
            title: "非表示の決まりをまとめて削除しますか",
            message: "貯めた記録があるものは残ります",
            keepTitle: "やめる",
            confirmTitle: "まとめて削除する"
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
            items: model.shown,
            drag: drag,
            space: Self.space
        ) { rule in
            tileFace(rule, isHidden: false)
        } onTap: { rule in
            destination = .edit(rule.id)
        } onFollow: { id, location in
            controller.follow(id, to: location)
        } onDrop: {
            controller.drop()
        }
    }

    var hiddenSection: some View {
        SettingsHiddenTiles(
            flag: hiddenList,
            title: "非表示の決まり",
            items: model.hidden,
            drag: drag,
            grid: grid,
            space: Self.space
        ) { rule in
            tileFace(rule, isHidden: true)
        } onTap: { rule in
            destination = .edit(rule.id)
        } onFollow: { id, location in
            controller.followHidden(id, to: location)
        } onDrop: {
            controller.dropHidden()
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

    static let columnCount = 2
    static let spacing: CGFloat = 12
    static let tileHeight: CGFloat = 156

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
