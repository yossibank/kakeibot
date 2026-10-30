import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateListView: View {
    @State var drag = SettingsDrag<EntryTemplate.ID>()
    @State var model: TemplateListModel
    @State var hiddenId: EntryTemplate.ID?
    @State var deletion: Deletion?
    @State var deleting: EntryTemplate.ID?
    @State var isConfirmingDelete = false

    @State var grid = SettingsBoardGrid(
        columns: 1,
        itemHeight: TemplateRowCard.height,
        spacing: 12
    )

    @State private var hintFlag: SettingsScreenFlag
    @State private var destination: Destination?
    @State private var isConfirmingDeleteHidden = false
    @State private var openId: EntryTemplate.ID?
    @State private var hiddenList: SettingsScreenFlag

    private let database: AppDatabase

    public init(database: AppDatabase) {
        let hintFlag = SettingsScreenFlag.closedHint(.templates, in: database)
        let hiddenList = SettingsScreenFlag.openHiddenList(.templates, in: database)
        let model = TemplateListModel(database: database)

        _model = State(initialValue: model)
        _hintFlag = State(initialValue: hintFlag)
        _hiddenList = State(initialValue: hiddenList)

        self.database = database
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("テンプレート", hint: hintFlag)

            SettingsIntroCard(
                systemImage: "rectangle.stack",
                headline: ("よく使う入力を", "1 回で記録できます"),
                notes: notes,
                flag: hintFlag
            )

            CapsulePicker(selection: $model.type, options: Self.typeOptions)

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    if model.shown.isEmpty {
                        SettingsEmptyNote(
                            systemImage: "rectangle.stack",
                            text: "テンプレートを足すと、ここに並びます"
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
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .padding(.horizontal, -20)
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
                SettingsHideTarget(zones: $drag.zones, isArmed: drag.isOverHide)
            } else {
                AddButton(addTitle) {
                    destination = .new(model.type)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .settingsLiftLayer(drag, size: liftSize, scale: 1.03) { id in
            floatingTile(id)
        }
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
            TemplateEditSheet(
                model: editModel(for: destination),
                onDelete: { deletion in
                    self.deletion = deletion
                },
                onHide: {
                    if case let .edit(id) = destination {
                        hiddenId = id
                    }
                }
            )
            .toolbar(.hidden, for: .navigationBar)
            .environment(\.isSettingsEditPushed, true)
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
        VStack(alignment: .leading, spacing: 12) {
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
        let opacity: Double = isLifted ? 0 : 0.5
        let layer: Double = isLifted ? 1 : 0

        return card(template)
            .opacity(opacity)
            .animation(nil, value: isLifted)
            .offset(offset)
            .settingsLiftFrame(drag, \.hiddenFrames, id: template.id, in: Self.space)
            .zIndex(layer)
            .onTapGesture {
                destination = .edit(template.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(template.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    @ViewBuilder
    func floatingTile(_ id: EntryTemplate.ID) -> some View {
        let items = model.shown + model.hidden

        if let template = items.first(where: { $0.id == id }) {
            card(template)
        }
    }

    func movableCard(_ template: EntryTemplate) -> some View {
        let isLifted = drag.isLifted(template.id)
        let index = model.shown.firstIndex(of: template) ?? 0
        let position = isLifted ? drag.liftedCenter : grid.center(at: index)
        let opacity: Double = isLifted ? 0 : 1
        let layer: Double = isLifted ? 1 : 0

        return SwipeRow(id: template.id, openId: $openId, role: .hide) {
            destination = .edit(template.id)
        } onAction: {
            hide(template.id)
        } onDelete: {
            requestDelete(template.id)
        } content: {
            card(template)
        }
        .frame(width: grid.itemWidth, height: grid.itemHeight)
        .opacity(opacity)
        .animation(nil, value: isLifted)
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
    enum Destination: Hashable {
        case new(Entry.Kind)
        case edit(EntryTemplate.ID)
    }

    nonisolated static let space = "TemplateBoard"

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    var typeName: String {
        model.type == .income ? "収入" : "支出"
    }

    var addTitle: String {
        "\(typeName)のテンプレートを追加"
    }

    var notes: [SettingsIntroCard.Note] {
        let purpose: [SettingsIntroCard.Note] = [
            .init("hand.tap", "金額を決めておくと、押すだけで記録します"),
            .init("apps.iphone", "ウィジェットからも記録できます")
        ]

        if model.shown.isEmpty {
            return purpose
        }

        return purpose + [
            .init("list.number", "この順でホームと入力シートに出ます"),
            .arrange,
            .swipeDelete
        ]
    }

    var boardHeight: CGFloat {
        grid.height(slots: model.shown.count)
    }

    var liftSize: CGSize {
        CGSize(width: grid.itemWidth, height: grid.itemHeight)
    }

    func editModel(for destination: Destination) -> TemplateEditModel {
        switch destination {
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
