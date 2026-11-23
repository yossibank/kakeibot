import Core
import DesignSystem
import Store
import SwiftUI

public struct CategoryListView: View {
    @State var drag = SettingsDrag<EntryCategory.ID>()
    @State var model: CategoryListModel
    @State var hiddenId: EntryCategory.ID?
    @State var deletion: Deletion?
    @State var bulkDelete: SettingsBulkDelete?

    @State var grid = Self.tiles

    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    private let database: AppDatabase

    public init(
        database: AppDatabase,
        kind: EntryCategory.Kind = .expense
    ) {
        let hintFlag = SettingsScreenFlag.closedHint(.categories, in: database)
        let hiddenList = SettingsScreenFlag.openHiddenList(.categories, in: database)
        let model = CategoryListModel(database: database)

        model.kind = kind

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
        _hiddenList = State(initialValue: hiddenList)

        self.database = database
    }

    public var body: some View {
        SettingsBoardScreen(
            title: "カテゴリ",
            hint: hintFlag,
            intro: SettingsIntroCard(
                systemImage: "tag",
                headline: ("支出と収入を", "分けて振り返れます"),
                notes: [
                    .init("arrow.left.arrow.right", "下で支出と収入を切り替えます"),
                    .init("number", "開くと、タグで細かく分けられます"),
                    .arrange
                ],
                flag: hintFlag
            ),
            emptyNote: .init(systemImage: "tag", text: "カテゴリを足すと、ここに並びます"),
            addTitle: addTitle,
            space: Self.space,
            tileHeight: Self.tiles.itemHeight,
            liftScale: 1.1,
            controller: controller,
            errorNotice: $model.errorNotice
        ) {
            destination = .new(model.kind)
        } header: {
            CapsulePicker(selection: $model.kind, options: Self.kindOptions)
        } board: {
            board
        } hiddenSection: {
            hiddenSection
        } floatingTile: { id in
            floatingTile(id)
        }
        .navigationDestination(item: $destination) { destination in
            CategoryEditSheet(model: editModel(for: destination)) { _ in } onDelete: { deletion in
                self.deletion = deletion
            } onHide: {
                if case let .edit(_, id) = destination {
                    hiddenId = id
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.isSettingsEditPushed, true)
        }
        .settingsDeleteHiddenConfirmation(
            isPresented: $isConfirmingDeleteHidden,
            title: "非表示のカテゴリをまとめて削除しますか",
            message: "記録があるカテゴリは残ります。使っている固定費・テンプレート・予算・タグも消えます"
        ) {
            controller.deleteHidden()
        }
        .task {
            await model.observe()
        }
    }
}

private extension CategoryListView {
    var board: some View {
        SettingsTileBoard(
            grid: $grid,
            controller: controller,
            space: Self.space
        ) { category in
            tileFace(category, isHidden: false)
        } onTap: { category in
            destination = .edit(category.kind, category.id)
        }
    }

    var hiddenSection: some View {
        SettingsHiddenTiles(
            flag: hiddenList,
            title: "非表示のカテゴリ",
            grid: grid,
            controller: controller,
            space: Self.space
        ) { category in
            tileFace(category, isHidden: true)
        } onTap: { category in
            destination = .edit(category.kind, category.id)
        } onDeleteAll: {
            isConfirmingDeleteHidden = true
        }
    }

    @ViewBuilder
    func floatingTile(_ id: EntryCategory.ID) -> some View {
        if let category = (model.shown + model.hidden).first(where: { $0.id == id }) {
            tileFace(category, isHidden: false)
        }
    }

    func tileFace(
        _ category: EntryCategory,
        isHidden: Bool
    ) -> some View {
        CategoryTileFace(
            icon: model.icon(for: category),
            name: category.name,
            isHidden: isHidden
        )
        .contentShape(.rect)
    }
}

private extension CategoryListView {
    enum Destination: Hashable {
        case new(EntryCategory.Kind)
        case edit(EntryCategory.Kind, EntryCategory.ID)
    }

    nonisolated static let space = "CategoryBoard"

    static let tiles = SettingsBoardGrid(columns: 4, itemHeight: 78, spacing: 8)

    static let kindOptions: [CapsulePicker<EntryCategory.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    var addTitle: String {
        model.kind == .income ? "収入のカテゴリを追加" : "支出のカテゴリを追加"
    }

    var controller: SettingsBoardController<CategoryListModel> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: grid,
            hiddenId: $hiddenId,
            deletion: $deletion,
            bulkDelete: $bulkDelete
        )
    }

    func editModel(for destination: Destination) -> CategoryEditModel {
        switch destination {
        case let .new(kind): CategoryEditModel(database: database, kind: kind)
        case let .edit(kind, id): CategoryEditModel(database: database, kind: kind, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            CategoryListView(database: database)
        }
    }
}
