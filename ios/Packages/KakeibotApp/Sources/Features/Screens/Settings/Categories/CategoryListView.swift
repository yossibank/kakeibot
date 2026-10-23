import Core
import DesignSystem
import Store
import SwiftUI

public struct CategoryListView: View {
    @State private var drag = SettingsDrag<EntryCategory.ID>()
    @State private var model: CategoryListModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var grid = SettingsBoardGrid(
        columns: Self.columnCount,
        itemHeight: Self.tileHeight,
        spacing: Self.spacing
    )
    @State private var hiddenId: EntryCategory.ID?
    @State private var deletion: Deletion?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    @Environment(\.themeStyle.corner) private var corner

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: CategoryListModel(database: database))
        let hintFlag = SettingsScreenFlag.closedHint(.categories, in: database)
        _hintFlag = State(initialValue: hintFlag)
        let hiddenList = SettingsScreenFlag.openHiddenList(
            .categories,
            in: database
        )
        _hiddenList = State(initialValue: hiddenList)
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("カテゴリ", hint: hintFlag)
            CapsulePicker(selection: $model.kind, options: Self.kindOptions)

            SettingsHint(
                flag: hintFlag,
                lines: [.move, .hide]
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .settingsLiftLayer(
            drag,
            size: CGSize(width: grid.itemWidth, height: Self.tileHeight),
            scale: 1.1
        ) { id in
            floatingTile(id)
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.impact(weight: .medium), trigger: drag.liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
        .sensoryFeedback(.success, trigger: drag.showCount)
        .navigationDestination(item: $destination) { destination in
            CategoryEditSheet(model: editModel(for: destination)) { _ in
            } onDelete: { deletion in
                self.deletion = deletion
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

            addTile
                .frame(width: grid.itemWidth, height: Self.tileHeight)
                .position(grid.center(at: model.shown.count))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: boardHeight)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            grid.width = width
        }
    }

    var addTile: some View {
        Button {
            destination = .new(model.kind)
        } label: {
            Image(systemName: "plus")
                .sansFont(.headline, weight: .ultraLight)
                .foregroundStyle(Palette.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.faint, in: tileShape)
                .overlay {
                    tileShape
                        .stroke(Palette.outline, style: .dashed)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
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
        let items = model.shown + model.hidden

        if let category = items.first(where: { $0.id == id }) {
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
        let icon = model.icon(for: category)
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.subtext
        let opacity: Double = isHidden ? 0.6 : 1

        return VStack(spacing: 6) {
            IconImage(icon, size: 20)
                .foregroundStyle(Palette.accent)

            Text(category.name)
                .textFont(size: .caption)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(color)
                .frame(width: 24, height: 2)
                .padding(.bottom, 7)
        }
        .background(tileBackground(isHidden: isHidden))
        .overlay {
            tileBorder(isHidden: isHidden)
        }
        .opacity(opacity)
        .contentShape(.rect)
    }

    @ViewBuilder
    func tileBackground(isHidden: Bool) -> some View {
        if !isHidden {
            tileShape
                .fill(Self.tileFill)
        }
    }

    @ViewBuilder
    func tileBorder(isHidden: Bool) -> some View {
        if isHidden {
            tileShape
                .stroke(Palette.subtext.opacity(.muted), style: .dashed)
        } else {
            tileShape
                .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
        }
    }
}

private extension CategoryListView {
    enum Destination: Hashable {
        case new(EntryCategory.Kind)
        case edit(EntryCategory.Kind, EntryCategory.ID)
    }

    static let kindOptions: [CapsulePicker<EntryCategory.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    nonisolated static let space = "CategoryBoard"
    static let columnCount = 4
    static let spacing: CGFloat = 8
    static let tileHeight: CGFloat = 78

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: spacing),
        count: columnCount
    )

    static var tileFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var boardHeight: CGFloat {
        grid.height(slots: model.shown.count + 1)
    }

    func follow(
        _ category: EntryCategory,
        to location: CGPoint
    ) {
        let index = model.shown.firstIndex(of: category) ?? 0
        let start = grid.center(at: index)

        let center = drag
            .follow(category.id, from: start, to: location) { next in
                follow(category, to: next)
            }

        guard let center else {
            return
        }

        let target = grid.index(at: center, count: model.shown.count)

        withAnimation(.snappy) {
            model.move(category.id, to: target)
        }
    }

    func drop() {
        switch drag.drop() {
        case let .hide(id):
            hide(id)
        case .move:
            Task {
                await model.finishMoving()
            }
        case nil:
            break
        }
    }

    func followHidden(
        _ id: EntryCategory.ID,
        to location: CGPoint
    ) {
        drag.followHidden(id, to: location)
    }

    func dropHidden() {
        guard let id = drag.dropHidden() else {
            return
        }

        show(id)
    }

    func hide(_ id: EntryCategory.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
        }
    }

    func deleteHidden() {
        Task {
            deletion = await model.deleteHidden()
        }
    }

    func restore(_ deletion: Deletion) {
        Task {
            await model.restore(deletion)
        }
    }

    func show(_ id: EntryCategory.ID) {
        Task {
            await model.show(id)
        }
    }

    func editModel(for destination: Destination) -> CategoryEditModel {
        switch destination {
        case let .new(kind):
            CategoryEditModel(database: database, kind: kind)
        case let .edit(kind, id):
            CategoryEditModel(database: database, kind: kind, editing: id)
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
