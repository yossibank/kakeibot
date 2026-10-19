import Core
import DesignSystem
import Store
import SwiftUI

public struct ShelfIconListView: View {
    @State private var model: ShelfIconListModel
    @State private var sheet: Sheet?
    @State private var lift: Lift?
    @State private var liftCount = 0
    @State private var boardWidth: CGFloat = 0
    @State private var removeZone: CGRect = .zero
    @State private var isOverRemoveZone = false
    @State private var removingId: ShelfIcon.ID?
    @State private var isConfirmingRemove = false

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: ShelfIconListModel(database: database))
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            Text("カテゴリ・口座・スタンプで使えます。長押しで動かせます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    board

                    if lift != nil {
                        removeTarget
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
        .confirmsShelfIconDelete(isPresented: $isConfirmingRemove) {
            confirmRemove()
        }
        .onChange(of: isConfirmingRemove) {
            keepIfNotRemoved()
        }
        .sheet(item: $sheet) { sheet in
            ShelfIconEditSheet(model: editModel(for: sheet))
        }
        .task {
            await model.observe()
        }
    }
}

private extension ShelfIconListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("アイコンの棚")
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
            ForEach(model.shown) { shelfIcon in
                movableTile(shelfIcon)
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
            sheet = .new
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

    var removeTarget: some View {
        SettingsHideZone(
            isTargeted: isOverRemoveZone,
            height: Self.tileHeight,
            title: "ここに置くと棚から消します",
            systemImage: "trash"
        )
        .onGeometryChange(for: CGRect.self) { proxy in
            proxy.frame(in: .named(Self.space))
        } action: { frame in
            removeZone = frame
        }
    }

    func movableTile(_ shelfIcon: ShelfIcon) -> some View {
        let isLifted = lift?.id == shelfIcon.id
        let index = model.shown.firstIndex(of: shelfIcon) ?? 0
        let position = isLifted ? liftedCenter : center(at: index)
        let scale: CGFloat = isLifted ? 1.1 : 1
        let shadow = Color.black.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return tileFace(shelfIcon)
            .frame(width: tileWidth, height: Self.tileHeight)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .position(position)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(shelfIcon.id)
            }
            .gesture(
                LiftGesture(in: Self.space) { location in
                    follow(shelfIcon, to: location)
                } onEnd: {
                    drop()
                }
            )
    }

    func tileFace(_ shelfIcon: ShelfIcon) -> some View {
        IconBadge(model.icon(for: shelfIcon), size: 44)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Self.tileFill, in: Self.tileShape)
            .overlay {
                Self.tileShape
                    .stroke(Palette.gold.opacity(.soft), lineWidth: 1)
            }
            .contentShape(.rect)
    }
}

private extension ShelfIconListView {
    struct Lift {
        let id: ShelfIcon.ID
        var location: CGPoint
        var grab: CGSize?
    }

    enum Sheet: Identifiable {
        case new
        case edit(ShelfIcon.ID)

        var id: String {
            switch self {
            case .new: "new"
            case let .edit(id): "edit-\(id)"
            }
        }
    }

    nonisolated static let space = "ShelfIconBoard"
    static let columnCount = 4
    static let spacing: CGFloat = 8
    static let tileHeight: CGFloat = 78
    static let tileShape = RoundedRectangle(cornerRadius: 16)

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
        _ shelfIcon: ShelfIcon,
        to location: CGPoint
    ) {
        if lift == nil {
            let index = model.shown.firstIndex(of: shelfIcon) ?? 0
            let start = center(at: index)

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: shelfIcon.id, location: start)
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
        isOverRemoveZone = removeZone.contains(location)

        guard !isOverRemoveZone else {
            return
        }

        let target = index(at: liftedCenter)

        withAnimation(.snappy) {
            model.move(shelfIcon.id, to: target)
        }
    }

    func drop() {
        guard let lift else {
            return
        }

        if isOverRemoveZone {
            withAnimation(.snappy) {
                self.lift = nil
                isOverRemoveZone = false
            }

            removingId = lift.id
            isConfirmingRemove = true
            return
        }

        withAnimation(.snappy) {
            self.lift = nil
        }

        Task {
            await model.finishMoving()
        }
    }

    func confirmRemove() {
        guard let removingId else {
            return
        }

        self.removingId = nil

        Task {
            await model.remove(removingId)
        }
    }

    func keepIfNotRemoved() {
        guard
            !isConfirmingRemove,
            removingId != nil
        else {
            return
        }

        removingId = nil

        withAnimation(.snappy) {
            model.cancelMoving()
        }
    }

    func editModel(for sheet: Sheet) -> ShelfIconEditModel {
        switch sheet {
        case .new:
            ShelfIconEditModel(database: database)
        case let .edit(id):
            ShelfIconEditModel(database: database, editing: id)
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertShelfIfEmpty(at: Date())

        NavigationStack {
            ShelfIconListView(database: database)
        }
    }
}
