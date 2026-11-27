import DesignSystem
import FeatureModels
import SwiftUI

struct SettingsBoardScreen<
    Model: SettingsBoardModel,
    Header: View,
    Board: View,
    HiddenSection: View,
    Floating: View
>: View {
    let title: String
    let hint: SettingsFold
    let intro: SettingsIntroCard
    let emptyNote: EmptyNote
    let addTitle: String
    let space: String
    let tileHeight: CGFloat?
    let scrollMargin: CGFloat
    let hideMessage: String
    let liftScale: CGFloat
    let controller: SettingsBoardController<Model>
    let errorNotice: ErrorNotice
    let onAdd: () -> Void
    let header: Header
    let board: Board
    let hiddenSection: HiddenSection
    let floatingTile: (Model.Item.ID) -> Floating

    init(
        title: String,
        hint: SettingsFold,
        intro: SettingsIntroCard,
        emptyNote: EmptyNote,
        addTitle: String,
        space: String,
        tileHeight: CGFloat? = nil,
        scrollMargin: CGFloat = 0,
        hideMessage: String = "非表示にしました",
        liftScale: CGFloat,
        controller: SettingsBoardController<Model>,
        errorNotice: ErrorNotice,
        onAdd: @escaping () -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder board: () -> Board,
        @ViewBuilder hiddenSection: () -> HiddenSection,
        @ViewBuilder floatingTile: @escaping (Model.Item.ID) -> Floating
    ) {
        self.title = title
        self.hint = hint
        self.intro = intro
        self.emptyNote = emptyNote
        self.addTitle = addTitle
        self.space = space
        self.tileHeight = tileHeight
        self.scrollMargin = scrollMargin
        self.hideMessage = hideMessage
        self.liftScale = liftScale
        self.controller = controller
        self.errorNotice = errorNotice
        self.onAdd = onAdd
        self.header = header()
        self.board = board()
        self.hiddenSection = hiddenSection()
        self.floatingTile = floatingTile
    }

    var body: some View {
        let drag = controller.drag
        let model = controller.model

        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader(title, hint: hint)

            intro

            header

            scroll

            footer
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .settingsLiftLayer(drag, size: liftSize, scale: liftScale) { id in
            floatingTile(id)
        }
        .errorBanner(errorNotice)
        .backdrop()
        .toolbar(.hidden, for: .navigationBar)
        .settingsBoardHaptics(drag, movingOrder: model.state.fields.movingOrder)
    }
}

extension SettingsBoardScreen {
    struct EmptyNote {
        let systemImage: String
        let text: String
    }
}

private extension SettingsBoardScreen {
    var scroll: some View {
        let drag = controller.drag
        let model = controller.model
        let removed = controller.removed

        return ScrollView {
            VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                if model.output.shown.isEmpty {
                    SettingsEmptyNote(
                        systemImage: emptyNote.systemImage,
                        text: emptyNote.text
                    )
                }

                board

                if !model.output.hidden.isEmpty {
                    hiddenSection
                }
            }
            .padding(.vertical, 8)
            .coordinateSpace(.named(space))
            .onGeometryChange(for: CGPoint.self) { proxy in
                proxy.frame(in: .global).origin
            } action: { origin in
                drag.origin = origin
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, scrollMargin, for: .scrollContent)
        .padding(.horizontal, -scrollMargin)
        .scrollDisabled(drag.isLifting)
        .settingsAutoScroll(drag.autoScroll)
        .settingsDropZones(Bindable(drag).zones, showing: drag.showZone)
        .undoNotice(removed.hidden, message: hideMessage) { id in
            controller.show(id)
        }
        .deletionNotice(removed.deletion, note: removed.bulkNote) { deletion in
            controller.restore(deletion)
        }
    }

    @ViewBuilder
    var footer: some View {
        let drag = controller.drag

        if drag.lift != nil {
            SettingsHideTarget(
                zones: Bindable(drag).zones,
                isArmed: drag.isOverHide
            )
        } else {
            AddButton(addTitle, action: onAdd)
        }
    }
}

private extension SettingsBoardScreen {
    var liftSize: CGSize? {
        tileHeight.map { CGSize(width: controller.grid.itemWidth, height: $0) }
    }
}
