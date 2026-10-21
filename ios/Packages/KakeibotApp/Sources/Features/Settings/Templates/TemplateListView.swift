import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateListView: View {
    @State private var drag = SettingsDrag<EntryTemplate.ID>()
    @State private var model: TemplateListModel
    @State private var sheet: Sheet?
    @State private var grid = SettingsBoardGrid(
        columns: 1,
        itemHeight: TemplateRowCard.height,
        spacing: 10
    )
    @State private var hiddenId: EntryTemplate.ID?
    @State private var deletion: Deletion?
    @State private var isConfirmingDeleteHidden = false
    @State private var openId: EntryTemplate.ID?
    @State private var deleting: EntryTemplate.ID?
    @State private var isConfirmingDelete = false
    @State private var hiddenList: SettingsScreenFlag

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: TemplateListModel(database: database))
        let hiddenList = SettingsScreenFlag.openHiddenList(
            .templates,
            in: database
        )
        _hiddenList = State(initialValue: hiddenList)
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            SettingsBackHeader("テンプレート")
            CapsulePicker(selection: $model.type, options: Self.typeOptions)

            SettingsHint(
                flag: .closedHint(.templates, in: database),
                lines: hint
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
            .contentMargins(.horizontal, 18, for: .scrollContent)
            .padding(.horizontal, -18)
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
                    sheet = .new(model.type)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
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
        .sheet(item: $sheet) { sheet in
            TemplateEditSheet(model: editModel(for: sheet)) { _ in
            } onDelete: { deletion in
                self.deletion = deletion
            }
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "このテンプレートを削除しますか",
            message: "このテンプレートで記録したものは残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            if let deleting {
                delete(deleting)
            }
        }
        .confirmation(
            isPresented: $isConfirmingDeleteHidden,
            systemImage: "trash",
            title: "非表示のテンプレートをまとめて削除しますか",
            message: "テンプレートで記録したものは残ります",
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

private extension TemplateListView {
    var board: some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.shown) { template in
                movableCard(template)
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
        VStack(alignment: .leading, spacing: 10) {
            SettingsHiddenTitle(
                flag: hiddenList,
                title: "非表示のテンプレート",
                count: model.hidden.count
            ) {
                isConfirmingDeleteHidden = true
            }

            if hiddenList.isOn {
                ForEach(model.hidden) { template in
                    hiddenCard(template)
                }
            }
        }
    }

    func card(_ template: EntryTemplate) -> some View {
        TemplateRowCard(
            icon: model.icon(for: template),
            name: template.name,
            detail: model.detail(for: template),
            amount: template.amount
        )
    }

    func hiddenCard(_ template: EntryTemplate) -> some View {
        let lifted = drag.hiddenOffset(of: template.id)
        let isLifted = lifted != nil
        let offset = lifted ?? .zero
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let opacity: Double = isLifted ? 1 : 0.5
        let layer: Double = isLifted ? 1 : 0

        return card(template)
            .opacity(opacity)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .offset(offset)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(template.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(template.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    func movableCard(_ template: EntryTemplate) -> some View {
        let isLifted = drag.isLifted(template.id)
        let index = model.shown.firstIndex(of: template) ?? 0
        let position = isLifted ? drag.liftedCenter : grid.center(at: index)
        let scale: CGFloat = isLifted ? 1.03 : 1
        let shadow = Palette.shadow.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: template.id, openId: $openId, role: .hide) {
            sheet = .edit(template.id)
        } onAction: {
            hide(template.id)
        } onDelete: {
            requestDelete(template.id)
        } content: {
            card(template)
        }
        .frame(width: grid.itemWidth, height: grid.itemHeight)
        .scaleEffect(scale)
        .shadow(color: shadow, radius: 16, y: 8)
        .position(position)
        .zIndex(layer)
        .gesture(
            LiftGesture(in: Self.space) { location in
                follow(template, to: location)
            } onEnd: {
                drop()
            }
        )
    }
}

private extension TemplateListView {
    enum Sheet: Hashable, Identifiable {
        case new(Entry.Kind)
        case edit(EntryTemplate.ID)

        var id: Self {
            self
        }
    }

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    nonisolated static let space = "TemplateBoard"

    var typeName: String {
        model.type == .income ? "収入" : "支出"
    }

    var addTitle: String {
        "\(typeName)のテンプレートを追加"
    }

    var hint: [SettingsHint.Line] {
        if model.shown.isEmpty {
            [
                .init("tray.and.arrow.down", "よく使う入力を残しておけます"),
                .init("bolt", "ホームと入力シートからすぐ入れられます")
            ]
        } else {
            [
                .init("list.number", "この順でホームと入力シートに出ます"),
                .move,
                .hide,
                .swipeDelete
            ]
        }
    }

    var boardHeight: CGFloat {
        grid.height(slots: model.shown.count)
    }

    func follow(
        _ template: EntryTemplate,
        to location: CGPoint
    ) {
        let index = model.shown.firstIndex(of: template) ?? 0
        let start = grid.center(at: index)

        let center = drag
            .follow(template.id, from: start, to: location) { next in
                follow(template, to: next)
            }

        guard let center else {
            return
        }

        let target = grid.index(at: center, count: model.shown.count)

        withAnimation(.snappy) {
            model.move(template.id, to: target)
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
        _ id: EntryTemplate.ID,
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

    func hide(_ id: EntryTemplate.ID) {
        Task {
            if await model.hide(id) {
                hiddenId = id
            }
        }
    }

    func requestDelete(_ id: EntryTemplate.ID) {
        deleting = id
        isConfirmingDelete = true
    }

    func delete(_ id: EntryTemplate.ID) {
        Task {
            deletion = await model.delete(id)
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

    func show(_ id: EntryTemplate.ID) {
        Task {
            await model.show(id)
        }
    }

    func editModel(for sheet: Sheet) -> TemplateEditModel {
        switch sheet {
        case let .new(type):
            TemplateEditModel(database: database, type: type)
        case let .edit(id):
            TemplateEditModel(database: database, type: model.type, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            TemplateListView(database: database)
        }
    }
}
