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
    @State private var hideZone: CGRect = .zero
    @State private var isOverHideZone = false

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: CategoryListModel(database: database))
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header
            CapsulePicker(selection: $model.kind, options: Self.kindOptions)

            Text("長押しで動かす。下の枠に置くと隠す")
                .font(.caption)
                .foregroundStyle(Palette.mist)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    board

                    if lift != nil {
                        hideTarget
                    } else if !model.hidden.isEmpty {
                        hiddenSection
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Palette.rose)
                    }
                }
                .padding(.vertical, 8)
                .coordinateSpace(.named(Self.space))
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(lift != nil)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .medium), trigger: liftCount)
        .sensoryFeedback(.selection, trigger: model.movingOrder)
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
                .font(.system(size: 16, design: .serif))
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
                .font(.system(size: 22, weight: .ultraLight))
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Palette.gold.opacity(0.06), in: Self.tileShape)
                .overlay {
                    Self.tileShape
                        .stroke(Palette.gold.opacity(0.55), style: Self.dash)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    var hideTarget: some View {
        let color = isOverHideZone ? Palette.rose : Palette.mist

        return HStack(spacing: 8) {
            Image(systemName: "eye.slash")

            Text("ここに置いて隠す")
        }
        .font(.subheadline)
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, minHeight: Self.tileHeight)
        .background(hideFill, in: Self.tileShape)
        .overlay {
            Self.tileShape
                .stroke(color.opacity(0.6), style: Self.dash)
        }
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(Self.space))
        } action: { frame in
            hideZone = frame
        }
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("隠したカテゴリ")
                .font(.caption2)
                .tracking(2)
                .foregroundStyle(Palette.mist)

            LazyVGrid(columns: Self.columns, spacing: Self.spacing) {
                ForEach(model.hidden) { category in
                    Button {
                        sheet = .edit(category.kind, category.id)
                    } label: {
                        tileFace(category, isHidden: true)
                            .frame(height: Self.tileHeight)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
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
            .gesture(reorderGesture(for: category))
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
                .font(.system(size: 11))
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
                .stroke(Palette.mist.opacity(0.4), style: Self.dash)
        } else {
            Self.tileShape
                .stroke(Palette.gold.opacity(0.22), lineWidth: 1)
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
    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])

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

    var hideFill: Color {
        isOverHideZone ? Palette.rose.opacity(0.12) : Color.clear
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

    func reorderGesture(for category: EntryCategory) -> some Gesture {
        let drag = DragGesture(
            minimumDistance: 0,
            coordinateSpace: .named(Self.space)
        )

        return LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: drag)
            .onChanged { value in
                guard case let .second(true, drag) = value else {
                    return
                }

                follow(category, to: drag?.location)
            }
            .onEnded { _ in
                drop()
            }
    }

    func follow(
        _ category: EntryCategory,
        to location: CGPoint?
    ) {
        if lift == nil {
            let index = model.shown.firstIndex(of: category) ?? 0
            let start = center(at: index)

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: category.id, location: start)
            }

            liftCount += 1
        }

        guard let location, var current = lift else {
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
        isOverHideZone = hideZone.contains(location)

        guard !isOverHideZone else {
            return
        }

        let target = index(at: liftedCenter)

        withAnimation(.snappy) {
            model.move(category.id, to: target)
        }
    }

    func drop() {
        guard let lift else {
            return
        }

        if isOverHideZone {
            let id = lift.id

            withAnimation(.snappy) {
                self.lift = nil
                isOverHideZone = false
            }

            Task {
                await model.hide(id)
            }

            return
        }

        withAnimation(.snappy) {
            self.lift = nil
        }

        Task {
            await model.finishMoving()
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
