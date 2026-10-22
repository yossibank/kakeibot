import Core
import DesignSystem
import Store
import SwiftUI

public struct RewardRuleListView: View {
    @State private var drag = SettingsDrag<RewardRule.ID>()
    @State private var model: RewardRuleListModel
    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var grid = SettingsBoardGrid(
        columns: Self.columnCount,
        itemHeight: Self.tileHeight,
        spacing: Self.spacing
    )
    @State private var hiddenId: RewardRule.ID?
    @State private var deletion: Deletion?
    @State private var isConfirmingDeleteHidden = false
    @State private var hiddenList: SettingsScreenFlag

    @Environment(\.themeStyle.corner) private var corner

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: RewardRuleListModel(database: database))
        let hintFlag = SettingsScreenFlag.closedHint(.rewards, in: database)
        _hintFlag = State(initialValue: hintFlag)
        let hiddenList = SettingsScreenFlag.openHiddenList(
            .rewards,
            in: database
        )
        _hiddenList = State(initialValue: hiddenList)
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("ごほうび", hint: hintFlag)

            SettingsHint(
                flag: hintFlag,
                lines: [.init("gift", "達成すると貯金箱に貯まる決まりです"), .move, .hide]
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
            RewardRuleEditSheet(
                model: editModel(for: destination)
            ) { deletion in
                self.deletion = deletion
            }
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.isSettingsEditPushed, true)
        }
        .confirmation(
            isPresented: $isConfirmingDeleteHidden,
            systemImage: "trash",
            title: "非表示のごほうびをまとめて削除しますか",
            message: "貯めた記録も消えます",
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

private extension RewardRuleListView {
    var board: some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.shown) { rule in
                movableTile(rule)
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
                title: "非表示のごほうび",
                count: model.hidden.count
            ) {
                isConfirmingDeleteHidden = true
            }

            if hiddenList.isOn {
                LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                    ForEach(model.hidden) { rule in
                        hiddenTile(rule)
                    }
                }
            }
        }
    }

    func hiddenTile(_ rule: RewardRule) -> some View {
        let lifted = drag.hiddenOffset(of: rule.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let scale: CGFloat = isLifted ? 1.1 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return tileFace(rule, isHidden: true)
            .frame(height: Self.tileHeight)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .offset(offset)
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(rule.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(rule.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    func movableTile(_ rule: RewardRule) -> some View {
        let isLifted = drag.isLifted(rule.id)
        let index = model.shown.firstIndex(of: rule) ?? 0
        let position = isLifted ? drag.liftedCenter : grid.center(at: index)
        let scale: CGFloat = isLifted ? 1.1 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return tileFace(rule, isHidden: false)
            .frame(width: grid.itemWidth, height: Self.tileHeight)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .position(position)
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(rule.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    follow(rule, to: location)
                } onEnd: {
                    drop()
                }
            )
    }

    func tileFace(
        _ rule: RewardRule,
        isHidden: Bool
    ) -> some View {
        let opacity: Double = isHidden ? 0.6 : 1

        return VStack(spacing: 6) {
            IconBadge(model.icon(for: rule), size: 36)

            Text(rule.name)
                .textFont(.caption)
                .foregroundStyle(Palette.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(AmountText.text(rule.amount))
                .textFont(.caption2)
                .foregroundStyle(Palette.accent)
        }
        .padding(.horizontal, 8)
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

private extension RewardRuleListView {
    enum Destination: Hashable {
        case new
        case edit(RewardRule.ID)
    }

    nonisolated static let space = "RewardBoard"
    static let columnCount = 3
    static let spacing: CGFloat = 8
    static let tileHeight: CGFloat = 108

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
        _ rule: RewardRule,
        to location: CGPoint
    ) {
        let index = model.shown.firstIndex(of: rule) ?? 0
        let start = grid.center(at: index)

        let center = drag
            .follow(rule.id, from: start, to: location) { next in
                follow(rule, to: next)
            }

        guard let center else {
            return
        }

        let target = grid.index(at: center, count: model.shown.count)

        withAnimation(.snappy) {
            model.move(rule.id, to: target)
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
        _ id: RewardRule.ID,
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

    func hide(_ id: RewardRule.ID) {
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

    func show(_ id: RewardRule.ID) {
        Task {
            await model.show(id)
        }
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
