import Core
import DesignSystem
import Store
import SwiftUI

public struct StampListView: View {
    @State private var drag = SettingsDrag<ShelfIcon.ID>()
    @State private var model: StampListModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var grid = SettingsBoardGrid(
        columns: Self.columnCount,
        itemHeight: Self.tileHeight,
        spacing: Self.spacing
    )
    @State private var hiddenId: ShelfIcon.ID?
    @State private var deletion: Deletion?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    @Environment(\.themeStyle.corner) private var corner

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: StampListModel(database: database))
        let hintFlag = SettingsScreenFlag.closedHint(.stamps, in: database)
        _hintFlag = State(initialValue: hintFlag)
        let hiddenList = SettingsScreenFlag.openHiddenList(
            .stamps,
            in: database
        )
        _hiddenList = State(initialValue: hiddenList)
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("スタンプ", hint: hintFlag)

            SettingsHint(
                flag: hintFlag,
                lines: [.init("seal", "カレンダーに押すスタンプです"), .move, .hide]
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
            StampEditSheet(model: editModel(for: destination)) { deletion in
                self.deletion = deletion
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
            deleteHidden()
        }
        .task {
            await model.observe()
        }
    }
}

private extension StampListView {
    var board: some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.shown) { shelfIcon in
                movableTile(shelfIcon)
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
            destination = .new
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
                title: "非表示のスタンプ",
                count: model.hidden.count
            ) {
                isConfirmingDeleteHidden = true
            }

            if hiddenList.isOn {
                LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                    ForEach(model.hidden) { shelfIcon in
                        hiddenTile(shelfIcon)
                    }
                }
            }
        }
    }

    func hiddenTile(_ shelfIcon: ShelfIcon) -> some View {
        let lifted = drag.hiddenOffset(of: shelfIcon.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return tileFace(shelfIcon, isHidden: true)
            .frame(height: Self.tileHeight)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .offset(offset)
            .settingsLiftFrame(
                drag,
                \.hiddenFrames,
                id: shelfIcon.id,
                in: Self.space
            )
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(shelfIcon.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(shelfIcon.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    @ViewBuilder
    func floatingTile(_ id: ShelfIcon.ID) -> some View {
        let items = model.shown + model.hidden

        if let shelfIcon = items.first(where: { $0.id == id }) {
            tileFace(shelfIcon, isHidden: false)
        }
    }

    func movableTile(_ shelfIcon: ShelfIcon) -> some View {
        let isLifted = drag.isLifted(shelfIcon.id)
        let index = model.shown.firstIndex(of: shelfIcon) ?? 0
        let position = isLifted ? drag.liftedCenter : grid.center(at: index)
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return tileFace(shelfIcon, isHidden: false)
            .frame(width: grid.itemWidth, height: Self.tileHeight)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .position(position)
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(shelfIcon.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    follow(shelfIcon, to: location)
                } onEnd: {
                    drop()
                }
            )
    }

    func tileFace(
        _ shelfIcon: ShelfIcon,
        isHidden: Bool
    ) -> some View {
        let opacity: Double = isHidden ? 0.6 : 1

        return IconBadge(model.icon(for: shelfIcon), size: 44)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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

private extension StampListView {
    enum Destination: Hashable {
        case new
        case edit(ShelfIcon.ID)
    }

    nonisolated static let space = "StampBoard"
    static let columnCount = 4
    static let spacing: CGFloat = 8
    static let tileHeight: CGFloat = 78

    var tileShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

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

    var boardHeight: CGFloat {
        grid.height(slots: model.shown.count + 1)
    }

    func follow(
        _ shelfIcon: ShelfIcon,
        to location: CGPoint
    ) {
        let index = model.shown.firstIndex(of: shelfIcon) ?? 0
        let start = grid.center(at: index)

        let center = drag
            .follow(shelfIcon.id, from: start, to: location) { next in
                follow(shelfIcon, to: next)
            }

        guard let center else {
            return
        }

        let target = grid.index(at: center, count: model.shown.count)

        withAnimation(.snappy) {
            model.move(shelfIcon.id, to: target)
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
        _ id: ShelfIcon.ID,
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

    func hide(_ id: ShelfIcon.ID) {
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

    func show(_ id: ShelfIcon.ID) {
        Task {
            await model.show(id)
        }
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
