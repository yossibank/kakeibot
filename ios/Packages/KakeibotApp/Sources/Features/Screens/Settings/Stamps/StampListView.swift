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

    @State private var grid = SettingsBoardGrid(
        columns: Self.columnCount,
        itemHeight: Self.tileHeight,
        spacing: Self.spacing
    )

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
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("スタンプ", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "seal",
                headline: ("カレンダーに押して", "その日を残せます"),
                notes: [
                    .init("hand.tap", "押すと、絵と名前を変えられます"),
                    .arrange
                ],
                flag: hintFlag
            )

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    if model.shown.isEmpty {
                        SettingsEmptyNote(
                            systemImage: "seal",
                            text: "スタンプを足すと、ここに並びます"
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
            .deletionNotice($deletion) { deletion in
                controller.restore(deletion)
            }

            if drag.lift != nil {
                SettingsHideTarget(
                    zones: $drag.zones,
                    isArmed: drag.isOverHide
                )
            } else {
                AddButton("スタンプを追加") {
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
        .confirmation(
            isPresented: $isConfirmingDeleteHidden,
            systemImage: "trash",
            title: "非表示のスタンプをまとめて削除しますか",
            message: "カレンダーに押したスタンプは残ります",
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

private extension StampListView {
    var board: some View {
        SettingsTileBoard(
            grid: $grid,
            items: model.shown,
            drag: drag,
            space: Self.space
        ) { shelfIcon in
            tileFace(shelfIcon, isHidden: false)
        } onTap: { shelfIcon in
            destination = .edit(shelfIcon.id)
        } onFollow: { id, location in
            controller.follow(id, to: location)
        } onDrop: {
            controller.drop()
        }
    }

    var hiddenSection: some View {
        SettingsHiddenTiles(
            flag: hiddenList,
            title: "非表示のスタンプ",
            items: model.hidden,
            drag: drag,
            grid: grid,
            space: Self.space
        ) { shelfIcon in
            tileFace(shelfIcon, isHidden: true)
        } onTap: { shelfIcon in
            destination = .edit(shelfIcon.id)
        } onFollow: { id, location in
            controller.followHidden(id, to: location)
        } onDrop: {
            controller.dropHidden()
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

    static let columnCount = 4
    static let spacing: CGFloat = 8
    static let tileHeight: CGFloat = 78

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
