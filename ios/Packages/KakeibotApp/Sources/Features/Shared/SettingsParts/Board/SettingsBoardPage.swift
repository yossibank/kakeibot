import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsBoardPage<Spec: SettingsBoardSpec>: View {
    @State var model: Spec.Model

    @State private var drag = SettingsDrag<Spec.Model.Item.ID>()
    @State private var destination: Spec.Destination?
    @State private var hiddenId: Spec.Model.Item.ID?
    @State private var openId: Spec.Model.Item.ID?
    @State private var hiding: Spec.Model.Item?
    @State private var deleting: Spec.Model.Item?
    @State private var deletion: Deletion?
    @State private var bulkDelete: SettingsBulkDelete?
    @State private var isConfirmingHide = false
    @State private var isConfirmingDelete = false
    @State private var isConfirmingDeleteHidden = false
    @State private var grid: SettingsBoardGrid

    private let spec: Spec

    init(_ spec: Spec) {
        _model = State(initialValue: spec.makeModel())
        _grid = State(initialValue: spec.grid)

        self.spec = spec
    }

    var body: some View {
        SettingsBoardScreen(
            title: spec.title,
            hint: hint,
            intro: spec.intro(hint: hint, in: model),
            emptyNote: .init(
                systemImage: emptyNote.systemImage,
                text: emptyNote.text
            ),
            addTitle: spec.addTitle(in: model),
            space: spec.space,
            tileHeight: spec.layout == .swipeRows ? nil : spec.grid.itemHeight,
            scrollMargin: spec.scrollMargin,
            hideMessage: spec.hideMessage,
            liftScale: spec.liftScale,
            controller: controller,
            errorNotice: Bindable(model.state).errorNotice
        ) {
            destination = spec.newDestination(in: model)
        } header: {
            spec.header(in: model)
        } board: {
            spec.lead(in: model)

            board
        } hiddenSection: {
            hiddenSection
        } floatingTile: { id in
            floatingTile(id)
        }
        .settingsSharesTextScale(spec.scaleID(in: model))
        .navigationDestination(item: $destination) { destination in
            editor(for: destination)
        }
        .settingsConfirmation(
            hiding.flatMap { spec.hideConfirmation(of: $0, in: model) },
            isPresented: $isConfirmingHide
        ) {
            if let hiding {
                controller.hide(hiding.id)
            }
        }
        .settingsConfirmation(
            deleting.flatMap { spec.deleteConfirmation(of: $0, in: model) },
            isPresented: $isConfirmingDelete
        ) {
            if let deleting {
                confirmDelete(deleting)
            }
        }
        .settingsDeleteHiddenConfirmation(
            isPresented: $isConfirmingDeleteHidden,
            title: spec.deleteHiddenTitle,
            message: spec.deleteHiddenMessage
        ) {
            controller.deleteHidden()
        }
        .task {
            await model.observe()
        }
    }
}

private extension SettingsBoardPage {
    var controller: SettingsBoardController<Spec.Model> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: grid,
            hiddenId: $hiddenId,
            deletion: $deletion,
            bulkDelete: $bulkDelete
        )
    }

    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }

    var emptyNote: (systemImage: String, text: String) {
        spec.emptyNote(in: model)
    }

    @ViewBuilder
    var board: some View {
        switch spec.layout {
        case .tiles:
            SettingsTileBoard(
                grid: $grid,
                controller: controller,
                space: spec.space
            ) { item in
                tileFace(item, isHidden: false)
            } onTap: { item in
                destination = spec.destination(editing: item)
            }

        case .swipeCards:
            SettingsTileBoard(
                grid: $grid,
                controller: controller,
                space: spec.space
            ) { item in
                swipeFace(item)
            }

        case .swipeRows:
            SettingsRowBoard(
                items: model.output.shown,
                drag: drag,
                grid: grid,
                space: spec.space,
                face: { item in
                    swipeFace(item)
                },
                onFollow: { id, location in
                    controller.follow(id, to: location)
                },
                onDrop: {
                    drop()
                }
            )
        }
    }

    var hiddenSection: some View {
        SettingsHiddenTiles(
            fold: SettingsFold(\.hiddenList, in: model),
            title: spec.hiddenTitle,
            grid: grid,
            controller: controller,
            space: spec.space,
            layout: spec.layout
        ) { item in
            tileFace(item, isHidden: true)
        } onTap: { item in
            destination = spec.destination(editing: item)
        } onDeleteAll: {
            isConfirmingDeleteHidden = true
        }
    }

    @ViewBuilder
    func floatingTile(_ id: Spec.Model.Item.ID) -> some View {
        if let item = (model.output.shown + model.output.hidden).first(where: { $0.id == id }) {
            tileFace(item, isHidden: false)
        }
    }

    func tileFace(
        _ item: Spec.Model.Item,
        isHidden: Bool
    ) -> some View {
        spec.tile(item, in: model, isHidden: isHidden)
            .contentShape(.rect)
    }

    func swipeFace(_ item: Spec.Model.Item) -> some View {
        SwipeRow(id: item.id, openId: $openId, role: .hide) {
            destination = spec.destination(editing: item)
        } onAction: {
            requestHide(item)
        } onDelete: {
            requestDelete(item)
        } content: {
            tileFace(item, isHidden: false)
        }
    }

    func editor(for destination: Spec.Destination) -> some View {
        spec.editor(for: destination) { deletion in
            self.deletion = deletion
        } onHide: {
            if let id = spec.itemID(of: destination) {
                hiddenId = id
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.isSettingsEditPushed, true)
    }

    func drop() {
        controller.drop { id in
            let item = model.output.shown.first { $0.id == id }

            withAnimation(.snappy) {
                model.cancelMoving()
            }

            if let item {
                requestHide(item)
            } else {
                controller.hide(id)
            }
        }
    }

    func requestHide(_ item: Spec.Model.Item) {
        guard spec.hideConfirmation(of: item, in: model) != nil else {
            controller.hide(item.id)
            return
        }

        hiding = item
        isConfirmingHide = true
    }

    func requestDelete(_ item: Spec.Model.Item) {
        guard spec.deleteConfirmation(of: item, in: model) != nil else {
            controller.delete(item.id)
            return
        }

        deleting = item
        isConfirmingDelete = true
    }

    func confirmDelete(_ item: Spec.Model.Item) {
        if spec.deleteConfirmation(of: item, in: model)?.confirmsHide == true {
            requestHide(item)
        } else {
            controller.delete(item.id)
        }
    }
}
