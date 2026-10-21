import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateListView: View {
    @State private var model: TemplateListModel
    @State private var sheet: Sheet?
    @State private var lift: Lift?
    @State private var liftCount = 0
    @State private var boardWidth: CGFloat = 0
    @State private var zones = SettingsDropZones()
    @State private var autoScroll = SettingsAutoScroll()
    @State private var contentOrigin: CGPoint = .zero
    @State private var hideHover = SettingsHideHover()
    @State private var hiddenId: EntryTemplate.ID?
    @State private var openId: EntryTemplate.ID?
    @State private var deleting: EntryTemplate.ID?
    @State private var isConfirmingDelete = false
    @State private var hiddenList: SettingsScreenFlag
    @State private var hiddenLift: SettingsHiddenLift<EntryTemplate.ID>?
    @State private var isOverShowZone = false
    @State private var showCount = 0

    @Environment(\.dismiss) private var dismiss

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
            header
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
                    contentOrigin = origin
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 18, for: .scrollContent)
            .padding(.horizontal, -18)
            .scrollDisabled(lift != nil || hiddenLift != nil)
            .settingsAutoScroll(autoScroll)
            .settingsDropZones(
                $zones,
                showing: hiddenLift == nil ? nil : isOverShowZone
            )
            .settingsHideNotice($hiddenId) { id in
                show(id)
            }

            if lift != nil {
                SettingsHideTarget(zones: $zones, state: hideHover.state)
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
        .sensoryFeedback(.impact(weight: .medium), trigger: liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
        .sensoryFeedback(.success, trigger: showCount)
        .sheet(item: $sheet) { sheet in
            TemplateEditSheet(model: editModel(for: sheet))
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
        .task {
            await model.observe()
        }
    }
}

private extension TemplateListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("テンプレート")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

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
            boardWidth = width
        }
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsHiddenTitle(
                flag: hiddenList,
                title: "非表示のテンプレート",
                count: model.hidden.count
            )

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
        let isLifted = hiddenLift?.id == template.id
        let offset = isLifted ? hiddenLift?.offset ?? .zero : .zero
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
        let isLifted = lift?.id == template.id
        let index = model.shown.firstIndex(of: template) ?? 0
        let position = isLifted ? liftedCenter : center(at: index)
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
        .frame(width: tileWidth, height: Self.tileHeight)
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
    struct Lift {
        let id: EntryTemplate.ID
        var location: CGPoint
        var grab: CGSize?
    }

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
    static let columnCount = 1
    static let spacing: CGFloat = 10
    static let tileHeight = TemplateRowCard.height
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

    var tileWidth: CGFloat {
        let gaps = Self.spacing * CGFloat(Self.columnCount - 1)
        return max((boardWidth - gaps) / CGFloat(Self.columnCount), 0)
    }

    var boardHeight: CGFloat {
        let count = model.shown.count
        let rows = (count + Self.columnCount - 1) / Self.columnCount
        let gaps = Self.spacing * CGFloat(max(rows - 1, 0))
        return Self.tileHeight * CGFloat(rows) + gaps
    }

    var liftedCenter: CGPoint {
        guard let lift else {
            return .zero
        }

        let grab = lift.grab ?? .zero

        return CGPoint(
            x: lift.location.x + grab.width,
            y: lift.location.y + grab.height
        )
    }

    func center(at index: Int) -> CGPoint {
        let column = index % Self.columnCount
        let row = index / Self.columnCount
        let x = (tileWidth + Self.spacing) * CGFloat(column) + tileWidth / 2
        let y = (Self.tileHeight + Self.spacing) * CGFloat(row)

        return CGPoint(x: x, y: y + Self.tileHeight / 2)
    }

    func index(at point: CGPoint) -> Int {
        let width = tileWidth + Self.spacing
        let height = Self.tileHeight + Self.spacing
        let column = min(max(Int(point.x / width), 0), Self.columnCount - 1)
        let row = max(Int(point.y / height), 0)
        return min(row * Self.columnCount + column, model.shown.count - 1)
    }

    func follow(
        _ template: EntryTemplate,
        to location: CGPoint
    ) {
        if lift == nil {
            let index = model.shown.firstIndex(of: template) ?? 0
            let start = center(at: index)

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: template.id, location: start)
            }

            liftCount += 1
        }

        guard var current = lift else {
            return
        }

        if current.grab == nil {
            let start = current.location

            current.grab = CGSize(
                width: start.x - location.x,
                height: start.y - location.y
            )
        }

        current.location = location
        lift = current
        let isInside = zones.isOverHide(location, from: contentOrigin)
        hideHover.update(isInside: isInside)

        autoScroll.follow(
            y: location.y + contentOrigin.y,
            bottom: zones.hide.isEmpty ? nil : zones.hide.minY
        ) { delta in
            let shifted = CGPoint(x: location.x, y: location.y + delta)
            follow(template, to: shifted)
        }

        guard !hideHover.isInside else {
            return
        }

        let target = index(at: liftedCenter)

        withAnimation(.snappy) {
            model.move(template.id, to: target)
        }
    }

    func drop() {
        autoScroll.stop()

        guard let lift else {
            return
        }

        if hideHover.isArmed {
            let id = lift.id

            withAnimation(.snappy) {
                self.lift = nil
                hideHover.reset()
            }

            hide(id)

            return
        }

        hideHover.reset()

        withAnimation(.snappy) {
            self.lift = nil
        }

        Task {
            await model.finishMoving()
        }
    }

    func followHidden(
        _ id: EntryTemplate.ID,
        to location: CGPoint
    ) {
        if hiddenLift == nil {
            withAnimation(.snappy(duration: 0.2)) {
                hiddenLift = SettingsHiddenLift(
                    id: id,
                    start: location,
                    location: location
                )
            }

            liftCount += 1
        }

        hiddenLift?.location = location
        isOverShowZone = zones.isOverShow(location, from: contentOrigin)
    }

    func dropHidden() {
        guard let hiddenLift else {
            return
        }

        let isShowing = isOverShowZone

        withAnimation(.snappy) {
            self.hiddenLift = nil
            isOverShowZone = false
        }

        guard isShowing else {
            return
        }

        showCount += 1

        Task {
            await model.show(hiddenLift.id)
        }
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
            await model.delete(id)
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
