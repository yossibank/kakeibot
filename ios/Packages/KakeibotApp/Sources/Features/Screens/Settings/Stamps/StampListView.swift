import Core
import DesignSystem
import Store
import SwiftUI

public struct StampListView: View {
    @State private var drag = SettingsDrag<ShelfIcon.ID>()
    @State private var model: StampListModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var hiddenId: ShelfIcon.ID?
    @State private var deletion: Deletion?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    @State private var grid = Self.tiles

    private let database: AppDatabase

    public init(database: AppDatabase) {
        let hintFlag = SettingsScreenFlag.closedHint(.stamps, in: database)
        let hiddenList = SettingsScreenFlag.openHiddenList(.stamps, in: database)

        _model = State(initialValue: StampListModel(database: database))
        _hintFlag = State(initialValue: hintFlag)
        _hiddenList = State(initialValue: hiddenList)

        self.database = database
    }

    public var body: some View {
        SettingsBoardScreen(
            title: "スタンプ",
            hint: hintFlag,
            intro: SettingsIntroCard(
                systemImage: "seal",
                headline: ("カレンダーに押して", "その日を残せます"),
                notes: [
                    .init("hand.tap", "押すと、絵と名前を変えられます"),
                    .arrange
                ],
                flag: hintFlag
            ),
            emptyNote: .init(systemImage: "seal", text: "スタンプを足すと、ここに並びます"),
            addTitle: "スタンプを追加",
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
            StampEditSheet(model: editModel(for: destination)) { deletion in
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
            title: "非表示のスタンプをまとめて削除しますか",
            message: "カレンダーに押したスタンプは残ります"
        ) {
            controller.deleteHidden()
        }
        .task {
            await model.observe()
        }
    }
}

private extension StampListView {
    var board: some View {
        SettingsTileBoard(
            grid: $grid,
            controller: controller,
            space: Self.space
        ) { shelfIcon in
            tileFace(shelfIcon, isHidden: false)
        } onTap: { shelfIcon in
            destination = .edit(shelfIcon.id)
        }
    }

    var hiddenSection: some View {
        SettingsHiddenTiles(
            flag: hiddenList,
            title: "非表示のスタンプ",
            grid: grid,
            controller: controller,
            space: Self.space
        ) { shelfIcon in
            tileFace(shelfIcon, isHidden: true)
        } onTap: { shelfIcon in
            destination = .edit(shelfIcon.id)
        } onDeleteAll: {
            isConfirmingDeleteHidden = true
        }
    }

    @ViewBuilder
    func floatingTile(_ id: ShelfIcon.ID) -> some View {
        if let shelfIcon = (model.shown + model.hidden).first(where: { $0.id == id }) {
            tileFace(shelfIcon, isHidden: false)
        }
    }

    func tileFace(
        _ shelfIcon: ShelfIcon,
        isHidden: Bool
    ) -> some View {
        StampTileFace(icon: model.icon(for: shelfIcon), isHidden: isHidden)
            .contentShape(.rect)
    }
}

private extension StampListView {
    enum Destination: Hashable {
        case new
        case edit(ShelfIcon.ID)
    }

    nonisolated static let space = "StampBoard"

    static let tiles = SettingsBoardGrid(columns: 4, itemHeight: 78, spacing: 8)

    var controller: SettingsBoardController<StampListModel> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: grid,
            hiddenId: $hiddenId,
            deletion: $deletion
        )
    }

    func editModel(for destination: Destination) -> StampEditModel {
        switch destination {
        case .new:
            StampEditModel(database: database)

        case let .edit(id):
            StampEditModel(database: database, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertShelfIfEmpty(at: Date())

        NavigationStack {
            StampListView(database: database)
        }
    }
}
