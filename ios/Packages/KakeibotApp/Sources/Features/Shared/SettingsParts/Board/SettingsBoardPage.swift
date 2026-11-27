import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsBoardPage<Spec: SettingsBoardSpec>: View {
    @State var model: Spec.Model

    @State private var drag = SettingsDrag<Spec.Model.Item.ID>()
    @State private var layout = Layout()

    private let spec: Spec

    init(_ spec: Spec) {
        _model = State(initialValue: spec.makeModel())

        self.spec = spec
    }

    var body: some View {
        let prompt = model.state.presented.prompt
        let hiding = prompt?.hidingId
        let deleting = prompt?.deletingId

        screen
            .settingsSharesTextScale(spec.scaleID(in: model))
            .navigationDestination(
                item: Bindable(model.state).presented.destination
            ) { destination in
                editor(for: destination)
            }
            .settingsConfirmation(
                item(hiding).flatMap { spec.hideConfirmation(of: $0, in: model) },
                isPresented: isAsking(hiding.map(Prompt.hide))
            ) {
                if let hiding {
                    controller.hide(hiding)
                }
            }
            .settingsConfirmation(
                item(deleting).flatMap { spec.deleteConfirmation(of: $0, in: model) },
                isPresented: isAsking(deleting.map(Prompt.delete))
            ) {
                if let item = item(deleting) {
                    confirmDelete(item)
                }
            }
            .settingsDeleteHiddenConfirmation(
                isPresented: isAsking(prompt == .deleteHidden ? prompt : nil),
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
    struct Layout {
        var width: CGFloat = 0
    }

    typealias Prompt = SettingsBoardPrompt<Spec.Model.Item.ID>
}

private extension SettingsBoardPage {
    var screen: some View {
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
            errorNotice: model.state.notices.error
        ) {
            model.state.open(spec.newDestination(in: model))
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
    }

    @ViewBuilder
    var board: some View {
        switch spec.layout {
        case .tiles:
            SettingsTileBoard(
                grid: grid,
                width: $layout.width,
                controller: controller,
                space: spec.space
            ) { item in
                tileFace(item, isHidden: false)
            } onTap: { item in
                model.state.open(spec.destination(editing: item))
            }

        case .swipeCards:
            SettingsTileBoard(
                grid: grid,
                width: $layout.width,
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
        SettingsHiddenSection(
            fold: SettingsFold(\.hiddenList, in: model),
            title: spec.hiddenTitle,
            grid: grid,
            controller: controller,
            space: spec.space,
            layout: spec.layout
        ) { item in
            tileFace(item, isHidden: true)
        } onTap: { item in
            model.state.open(spec.destination(editing: item))
        } onDeleteAll: {
            model.state.ask(.deleteHidden)
        }
    }

    @ViewBuilder
    func floatingTile(_ id: Spec.Model.Item.ID) -> some View {
        if let item = item(id) {
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
        SwipeRow(id: item.id, openId: Bindable(model.state).presented.openId, role: .hide) {
            model.state.open(spec.destination(editing: item))
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
            model.receive(deletion)
        } onHide: {
            if let id = spec.itemID(of: destination) {
                model.receiveHidden(id)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.isSettingsEditPushed, true)
    }
}

private extension SettingsBoardPage {
    var grid: SettingsBoardGrid {
        var grid = spec.grid
        grid.width = layout.width
        return grid
    }

    var controller: SettingsBoardController<Spec.Model> {
        SettingsBoardController(
            model: model,
            drag: drag,
            grid: grid
        )
    }

    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }

    var emptyNote: (systemImage: String, text: String) {
        spec.emptyNote(in: model)
    }

    func item(_ id: Spec.Model.Item.ID?) -> Spec.Model.Item? {
        (model.output.shown + model.output.hidden).first { $0.id == id }
    }

    func isAsking(_ prompt: Prompt?) -> Binding<Bool> {
        Binding {
            prompt != nil
        } set: { isShown in
            if !isShown,
               let prompt {
                model.state.closePrompt(prompt)
            }
        }
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

        model.state.ask(.hide(item.id))
    }

    func requestDelete(_ item: Spec.Model.Item) {
        guard spec.deleteConfirmation(of: item, in: model) != nil else {
            controller.delete(item.id)
            return
        }

        model.state.ask(.delete(item.id))
    }

    func confirmDelete(_ item: Spec.Model.Item) {
        if spec.deleteConfirmation(of: item, in: model)?.confirmsHide == true {
            requestHide(item)
        } else {
            controller.delete(item.id)
        }
    }
}
