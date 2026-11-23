import Store
import SwiftUI

struct SettingsBoardPage<Spec: SettingsBoardSpec>: View {
    @State var model: Spec.Model

    @State private var drag = SettingsDrag<Spec.Model.Item.ID>()
    @State private var hintFlag: SettingsScreenFlag
    @State private var hiddenList: SettingsScreenFlag
    @State private var destination: Spec.Destination?
    @State private var hiddenId: Spec.Model.Item.ID?
    @State private var deletion: Deletion?
    @State private var bulkDelete: SettingsBulkDelete?
    @State private var isConfirmingDeleteHidden = false
    @State private var grid: SettingsBoardGrid

    private let spec: Spec

    init(_ spec: Spec) {
        let hintFlag = SettingsScreenFlag.closedHint(spec.screen, in: spec.database)
        let hiddenList = SettingsScreenFlag.openHiddenList(spec.screen, in: spec.database)

        _model = State(initialValue: spec.makeModel())
        _hintFlag = State(initialValue: hintFlag)
        _hiddenList = State(initialValue: hiddenList)
        _grid = State(initialValue: spec.grid)

        self.spec = spec
    }

    var body: some View {
        SettingsBoardScreen(
            title: spec.title,
            hint: hintFlag,
            intro: spec.intro(flag: hintFlag),
            emptyNote: .init(
                systemImage: spec.emptyNote.systemImage,
                text: spec.emptyNote.text
            ),
            addTitle: spec.addTitle(in: model),
            space: spec.space,
            tileHeight: spec.grid.itemHeight,
            scrollMargin: spec.scrollMargin,
            hideMessage: spec.hideMessage,
            liftScale: spec.liftScale,
            controller: controller,
            errorNotice: $model.errorNotice
        ) {
            destination = spec.newDestination(in: model)
        } header: {
            spec.header(in: model)
        } board: {
            board
        } hiddenSection: {
            hiddenSection
        } floatingTile: { id in
            floatingTile(id)
        }
        .navigationDestination(item: $destination) { destination in
            editor(for: destination)
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

    var board: some View {
        SettingsTileBoard(
            grid: $grid,
            controller: controller,
            space: spec.space
        ) { item in
            tileFace(item, isHidden: false)
        } onTap: { item in
            destination = spec.destination(editing: item)
        }
    }

    var hiddenSection: some View {
        SettingsHiddenTiles(
            flag: hiddenList,
            title: spec.hiddenTitle,
            grid: grid,
            controller: controller,
            space: spec.space
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
        if let item = (model.shown + model.hidden).first(where: { $0.id == id }) {
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
}
