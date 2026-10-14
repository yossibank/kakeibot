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

    @Environment(\.dismiss) private var dismiss

    private let database: AppDatabase

    public init(database: AppDatabase) {
        _model = State(initialValue: TemplateListModel(database: database))
        self.database = database
    }

    public var body: some View {
        VStack(spacing: 14) {
            header
            CapsulePicker(selection: $model.type, options: Self.typeOptions)

            Text(hint)
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .multilineTextAlignment(.center)

            ScrollView {
                VStack(spacing: 20) {
                    board

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

            addButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 8)
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
            TemplateEditSheet(model: editModel(for: sheet))
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
            ForEach(model.shown) { template in
                movableRow(template)
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

    var addButton: some View {
        Button {
            sheet = .new(model.type)
        } label: {
            Label(addTitle, systemImage: "plus")
                .font(.subheadline)
                .foregroundStyle(Palette.gold)
                .frame(maxWidth: .infinity, minHeight: 50)
                .background(Palette.gold.opacity(0.06), in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(Palette.gold.opacity(0.55), style: Self.dash)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func movableRow(_ template: EntryTemplate) -> some View {
        let isLifted = lift?.id == template.id
        let index = model.shown.firstIndex(of: template) ?? 0
        let position = isLifted ? liftedCenter : center(at: index)
        let scale: CGFloat = isLifted ? 1.04 : 1
        let shadow = Color.black.opacity(isLifted ? 0.5 : 0)
        let layer: Double = isLifted ? 1 : 0

        return rowFace(template)
            .frame(width: boardWidth, height: Self.rowHeight)
            .scaleEffect(scale)
            .shadow(color: shadow, radius: 16, y: 8)
            .position(position)
            .zIndex(layer)
            .onTapGesture {
                sheet = .edit(template.id)
            }
            .gesture(reorderGesture(for: template))
    }

    func rowFace(_ template: EntryTemplate) -> some View {
        HStack(spacing: 12) {
            IconImage(model.icon(for: template), size: 17)
                .foregroundStyle(Palette.gold)
                .frame(width: 38, height: 38)
                .overlay {
                    Circle()
                        .stroke(Palette.gold.opacity(0.35), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(template.name)
                    .font(.subheadline)
                    .foregroundStyle(Palette.ink)

                Text(model.detail(for: template))
                    .font(.caption2)
                    .foregroundStyle(Palette.mist)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Text(model.amountText(for: template))
                .font(.system(size: 15, design: .serif))
                .foregroundStyle(amountColor(for: template))
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Self.rowFill, in: Self.rowShape)
        .overlay {
            Self.rowShape
                .stroke(Palette.gold.opacity(0.18), lineWidth: 1)
        }
        .contentShape(.rect)
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
    static let rowHeight: CGFloat = 62
    static let spacing: CGFloat = 8
    static let rowShape = RoundedRectangle(cornerRadius: 18)
    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])

    static var rowFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var typeName: String {
        model.type == .income ? "収入" : "支出"
    }

    var addTitle: String {
        "\(typeName)のテンプレートを追加"
    }

    var hint: String {
        if model.shown.isEmpty {
            "よく使う入力を残しておくと、ホームと入力シートから 1 回で入れられる"
        } else {
            "長押しで動かす。この順でホームと入力シートに出る"
        }
    }

    var boardHeight: CGFloat {
        let count = model.shown.count
        let gaps = Self.spacing * CGFloat(max(count - 1, 0))
        return Self.rowHeight * CGFloat(count) + gaps
    }

    var liftedCenter: CGPoint {
        guard let lift else {
            return .zero
        }

        let grab = lift.grab ?? .zero

        return CGPoint(
            x: boardWidth / 2,
            y: lift.location.y + grab.height
        )
    }

    func amountColor(for template: EntryTemplate) -> Color {
        template.amount == nil ? Palette.mist : Palette.champagne
    }

    func center(at index: Int) -> CGPoint {
        let y = (Self.rowHeight + Self.spacing) * CGFloat(index)
        return CGPoint(x: boardWidth / 2, y: y + Self.rowHeight / 2)
    }

    func index(at point: CGPoint) -> Int {
        let height = Self.rowHeight + Self.spacing
        let row = max(Int(point.y / height), 0)
        return min(row, model.shown.count - 1)
    }

    func reorderGesture(for template: EntryTemplate) -> some Gesture {
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

                follow(template, to: drag?.location)
            }
            .onEnded { _ in
                drop()
            }
    }

    func follow(
        _ template: EntryTemplate,
        to location: CGPoint?
    ) {
        if lift == nil {
            let index = model.shown.firstIndex(of: template) ?? 0
            let start = center(at: index)

            withAnimation(.snappy(duration: 0.2)) {
                lift = Lift(id: template.id, location: start)
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

        let target = index(at: liftedCenter)

        withAnimation(.snappy) {
            model.move(template.id, to: target)
        }
    }

    func drop() {
        guard lift != nil else {
            return
        }

        withAnimation(.snappy) {
            lift = nil
        }

        Task {
            await model.finishMoving()
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
