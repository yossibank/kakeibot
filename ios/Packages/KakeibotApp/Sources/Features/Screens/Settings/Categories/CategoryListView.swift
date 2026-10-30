import Core
import DesignSystem
import Store
import SwiftUI

public struct CategoryListView: View {
    @State var drag = SettingsDrag<EntryCategory.ID>()
    @State var model: CategoryListModel
    @State var hiddenId: EntryCategory.ID?
    @State var deletion: Deletion?

    @State var grid = SettingsBoardGrid(
        columns: Self.columnCount,
        itemHeight: Self.tileHeight,
        spacing: Self.spacing
    )

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
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("カテゴリ", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "tag",
                headline: ("支出と収入を", "分けて振り返れます"),
                notes: [
                    .init("arrow.left.arrow.right", "下で支出と収入を切り替えます"),
                    .init("number", "開くと、タグで細かく分けられます"),
                    .arrange
                ],
                flag: hintFlag
            )

            CapsulePicker(selection: $model.kind, options: Self.kindOptions)

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    if model.shown.isEmpty {
                        SettingsEmptyNote(
                            systemImage: "tag",
                            text: "カテゴリを足すと、ここに並びます"
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
                show(id)
            }
            .deletionNotice($deletion) { deletion in
                restore(deletion)
            }

            if drag.lift != nil {
                SettingsHideTarget(
                    zones: $drag.zones,
                    isArmed: drag.isOverHide
                )
            } else {
                AddButton(addTitle) {
                    destination = .new(model.kind)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .settingsLiftLayer(
            drag,
            size: CGSize(width: grid.itemWidth, height: Self.tileHeight),
            scale: 1.1
        ) { id in
            floatingTile(id)
        }
        .sharesTextScale(id: model.shown + model.hidden)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .haptic(.impact(weight: .medium), trigger: drag.liftCount)
        .haptic(.selection, trigger: model.movingOrder)
        .haptic(.success, trigger: drag.showCount)
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
        .confirmation(
            isPresented: $isConfirmingDeleteHidden,
            systemImage: "trash",
            title: "非表示のカテゴリをまとめて削除しますか",
            message: "記録があるカテゴリは残ります。使っている固定費・テンプレート・予算・タグも消えます",
            keepTitle: "やめる",
            confirmTitle: "まとめて削除する"
        ) {
            deleteHidden()
        }
        .task {
            await model.observe()
        }
    }
}

private extension CategoryListView {
    var board: some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.shown) { category in
                movableTile(category)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: boardHeight)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            grid.width = width
        }
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsHiddenTitle(
                flag: hiddenList,
                title: "非表示のカテゴリ",
                count: model.hidden.count
            ) {
                isConfirmingDeleteHidden = true
            }

            if hiddenList.isOn {
                LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                    ForEach(model.hidden) { category in
                        hiddenTile(category)
                    }
                }
            }
        }
    }

    func hiddenTile(_ category: EntryCategory) -> some View {
        let lifted = drag.hiddenOffset(of: category.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return tileFace(category, isHidden: true)
            .frame(height: Self.tileHeight)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .offset(offset)
            .settingsLiftFrame(
                drag,
                \.hiddenFrames,
                id: category.id,
                in: Self.space
            )
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(category.kind, category.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(category.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    @ViewBuilder
    func floatingTile(_ id: EntryCategory.ID) -> some View {
        if let category = (model.shown + model.hidden).first(where: { $0.id == id }) {
            tileFace(category, isHidden: false)
        }
    }

    func movableTile(_ category: EntryCategory) -> some View {
        let isLifted = drag.isLifted(category.id)
        let index = model.shown.firstIndex(of: category) ?? 0
        let position = isLifted ? drag.liftedCenter : grid.center(at: index)
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return tileFace(category, isHidden: false)
            .frame(width: grid.itemWidth, height: Self.tileHeight)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .position(position)
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(category.kind, category.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    follow(category, to: location)
                } onEnd: {
                    drop()
                }
            )
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

    static let columnCount = 4
    static let spacing: CGFloat = 8
    static let tileHeight: CGFloat = 78

    static let kindOptions: [CapsulePicker<EntryCategory.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: spacing),
        count: columnCount
    )

    var addTitle: String {
        model.kind == .income ? "収入のカテゴリを追加" : "支出のカテゴリを追加"
    }

    var boardHeight: CGFloat {
        grid.height(slots: model.shown.count)
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
