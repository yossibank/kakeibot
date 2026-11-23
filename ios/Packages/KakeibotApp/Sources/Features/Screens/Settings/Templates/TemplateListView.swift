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
        itemHeight: TemplateRowCard.Fit.fill.height,
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
        SettingsBoardScreen(
            title: "テンプレート",
            hint: hintFlag,
            intro: SettingsIntroCard(
                systemImage: "rectangle.stack",
                headline: ("よく使う入力を", "1 回で記録できます"),
                notes: notes,
                flag: hintFlag
            ),
            emptyNote: .init(
                systemImage: "rectangle.stack",
                text: "テンプレートを足すと、ここに並びます"
            ),
            addTitle: addTitle,
            space: Self.space,
            tileHeight: grid.itemHeight,
            scrollMargin: 20,
            liftScale: 1.03,
            controller: controller,
            errorNotice: $model.errorNotice
        ) {
            destination = .new(model.type)
        } header: {
            CapsulePicker(selection: $model.type, options: Self.typeOptions)
        } board: {
            board
        } hiddenSection: {
            hiddenSection
        } floatingTile: { id in
            floatingTile(id)
        }
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
        .settingsDeleteConfirmation(
            isPresented: $isConfirmingDelete,
            title: "このテンプレートを削除しますか",
            message: "このテンプレートで記録したものは残ります"
        ) {
            if let deleting {
                controller.delete(deleting)
            }
        }
        .settingsDeleteHiddenConfirmation(
            isPresented: $isConfirmingDeleteHidden,
            title: "非表示のテンプレートをまとめて削除しますか",
            message: "テンプレートで記録したものは残ります"
        ) {
            controller.deleteHidden()
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
                    controller.followHidden(template.id, to: location)
                } onEnd: {
                    controller.dropHidden()
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
            controller.hide(template.id)
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
                controller.follow(template.id, to: location)
            } onEnd: {
                controller.drop()
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

    var controller: SettingsBoardController<TemplateListModel> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: grid,
            hiddenId: $hiddenId,
            deletion: $deletion
        )
    }

    func requestDelete(_ id: EntryTemplate.ID) {
        deleting = id
        isConfirmingDelete = true
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
