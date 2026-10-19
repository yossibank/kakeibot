import Core
import DesignSystem
import Store
import SwiftUI

public struct CategoryListView: View {
    @State private var model: CategoryListModel
    @State private var sheet: Sheet?
    @State private var lift: Lift?
    @State private var liftCount = 0
    @State private var boardWidth: CGFloat = 0
    @State private var zones = SettingsDropZones()
    @State private var autoScroll = SettingsAutoScroll()
    @State private var contentOrigin: CGPoint = .zero
    @State private var hideHover = SettingsHideHover()
    @State private var hiddenList: SettingsScreenFlag
    @State private var hiddenLift: SettingsHiddenLift<EntryCategory.ID>?
    @State private var isOverShowZone = false
    @State private var showCount = 0

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: CategoryListModel(database: database))
        let hiddenList = SettingsScreenFlag.openHiddenList(
            .categories,
            in: database
        )
        _hiddenList = State(initialValue: hiddenList)
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header
            CapsulePicker(selection: $model.kind, options: Self.kindOptions)

            SettingsHint(
                flag: .closedHint(.categories, in: database),
                lines: [.move, .hide]
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
            .scrollDisabled(lift != nil || hiddenLift != nil)
            .settingsAutoScroll(autoScroll)
            .settingsDropZones(
                $zones,
                hiding: lift == nil ? nil : hideHover.state,
                showing: hiddenLift == nil ? nil : isOverShowZone
            )
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
        .sensoryFeedback(.success, trigger: showCount)
        .sheet(item: $sheet) { sheet in
            CategoryEditSheet(model: editModel(for: sheet))
        }
        .task {
            await model.observe()
        }
    }
}

private extension CategoryListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("カテゴリ")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var board: some View {
        ZStack(alignment: .topLeading) {
            ForEach(model.shown) { category in
                movableTile(category)
            }

            addTile
                .frame(width: tileWidth, height: Self.tileHeight)
                .position(center(at: model.shown.count))
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: boardHeight)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            boardWidth = width
        }
    }

    var addTile: some View {
        Button {
            sheet = .new(model.kind)
        } label: {
            Image(systemName: "plus")
                .font(.sans(.headline, weight: .ultraLight))
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.faint, in: Self.tileShape)
                .overlay {
                    Self.tileShape
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
                title: "非表示のカテゴリ",
                count: model.hidden.count
            )

            if hiddenList.isOn {
                LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                    ForEach(model.hidden) { category in
                        hiddenTile(category)
                    }
                }
            }
        }
    }

    func hiddenTile(_ category: EntryCategory) -> some View {
        let isLifted = hiddenLift?.id == category.id
        let offset = isLifted ? hiddenLift?.offset ?? .zero : .zero
        let scale: CGFloat = isLifted ? 1.1 : 1
        let shadow = Color.black.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return tileFace(category, isHidden: true)
            .frame(height: Self.tileHeight)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .offset(offset)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(category.kind, category.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    followHidden(category.id, to: location)
                } onEnd: {
                    dropHidden()
                }
            )
    }

    func movableTile(_ category: EntryCategory) -> some View {
        let isLifted = lift?.id == category.id
        let index = model.shown.firstIndex(of: category) ?? 0
        let position = isLifted ? liftedCenter : center(at: index)
        let scale: CGFloat = isLifted ? 1.1 : 1
        let shadow = Color.black.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return tileFace(category, isHidden: false)
            .frame(width: tileWidth, height: Self.tileHeight)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .position(position)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(category.kind, category.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    follow(category, to: location)
                } onEnd: {
                    drop()
                }
            )
    }

    func tileFace(
        _ category: EntryCategory,
        isHidden: Bool
    ) -> some View {
        let icon = model.icon(for: category)
        let color = icon.flatMap { Color(hex: $0.color) } ?? Palette.mist
        let opacity: Double = isHidden ? 0.6 : 1

        return VStack(spacing: 6) {
            IconImage(icon, size: 20)
                .foregroundStyle(Palette.gold)

            Text(category.name)
                .font(.sans(.caption))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            Capsule()
                .fill(color)
                .frame(width: 24, height: 2)
                .padding(.bottom, 7)
        }
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
            Self.tileShape
                .fill(Self.tileFill)
        }
    }

    @ViewBuilder
    func tileBorder(isHidden: Bool) -> some View {
        if isHidden {
            Self.tileShape
                .stroke(Palette.mist.opacity(.muted), style: .dashed)
        } else {
            Self.tileShape
                .stroke(Palette.gold.opacity(.soft), lineWidth: 1)
        }
    }
}

private extension CategoryListView {
    struct Lift {
        let id: EntryCategory.ID
        var location: CGPoint
        var grab: CGSize?
    }

    enum Sheet: Identifiable {
        case new(EntryCategory.Kind)
        case edit(EntryCategory.Kind, EntryCategory.ID)

        var id: String {
            switch self {
            case let .new(kind): "new-\(kind.rawValue)"
            case let .edit(_, id): "edit-\(id)"
            }
        }
    }

    static let kindOptions: [CapsulePicker<EntryCategory.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income)
    ]

    nonisolated static let space = "CategoryBoard"
    static let columnCount = 4
    static let spacing: CGFloat = 8
    static let tileHeight: CGFloat = 78
    static let tileShape = RoundedRectangle(cornerRadius: 16)
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

    var tileWidth: CGFloat {
        let gaps = Self.spacing * CGFloat(Self.columnCount - 1)
        return max((boardWidth - gaps) / CGFloat(Self.columnCount), 0)
    }

    var boardHeight: CGFloat {
        let slots = model.shown.count + 1
        let rows = (slots + Self.columnCount - 1) / Self.columnCount
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
        _ category: EntryCategory,
        to location: CGPoint
    ) {
        if lift == nil {
            let index = model.shown.firstIndex(of: category) ?? 0
            let start = center(at: index)

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: category.id, location: start)
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
            follow(category, to: shifted)
        }

        guard !hideHover.isInside else {
            return
        }

        let target = index(at: liftedCenter)

        withAnimation(.snappy) {
            model.move(category.id, to: target)
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

            Task {
                await model.hide(id)
            }

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
        _ id: EntryCategory.ID,
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

    func editModel(for sheet: Sheet) -> CategoryEditModel {
        switch sheet {
        case let .new(kind):
            CategoryEditModel(database: database, kind: kind)
        case let .edit(kind, id):
            CategoryEditModel(database: database, kind: kind, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        NavigationStack {
            CategoryListView(database: database)
        }
    }
}
