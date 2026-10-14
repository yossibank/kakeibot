import Core
import DesignSystem
import Store
import SwiftUI
import UniformTypeIdentifiers

public struct CategoryListView: View {
    @State private var model: CategoryListModel
    @State private var sheet: Sheet?
    @State private var dragging: EntryCategory.ID?

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

            Text("入力シートと同じ並び。長押しで動かす")
                .font(.caption)
                .foregroundStyle(Palette.mist)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    shownGrid

                    if !model.hidden.isEmpty {
                        hiddenSection
                    }

                    if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(Palette.rose)
                    }
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
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
            RingButton("戻る", systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("カテゴリ")
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var shownGrid: some View {
        LazyVGrid(columns: Self.columns, spacing: 8) {
            ForEach(model.shown) { category in
                tile(category, isHidden: false)
                    .onDrag {
                        let text = category.id.description as NSString
                        dragging = category.id
                        return NSItemProvider(object: text)
                    } preview: {
                        tile(category, isHidden: false)
                            .frame(width: 80)
                    }
                    .onDrop(
                        of: [.text],
                        delegate: TileDrop(
                            dragging: $dragging,
                            target: category.id,
                            model: model
                        )
                    )
            }

            Button {
                sheet = .new(model.kind)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .ultraLight))
                    .foregroundStyle(Palette.gold)
                    .frame(maxWidth: .infinity, minHeight: Self.tileHeight)
                    .background(
                        Palette.gold.opacity(0.06),
                        in: .rect(cornerRadius: 16)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Self.addStroke, style: Self.dash)
                    }
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("カテゴリを足す")
        }
        .animation(.snappy, value: model.shown)
    }

    var hiddenSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("隠したカテゴリ")
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.mist)

            LazyVGrid(columns: Self.columns, spacing: 8) {
                ForEach(model.hidden) { category in
                    tile(category, isHidden: true)
                }
            }
        }
    }

    func tile(
        _ category: EntryCategory,
        isHidden: Bool
    ) -> some View {
        let color = model.icon(for: category).flatMap { Color(hex: $0.color) }
        let isDragging = dragging == category.id

        return Button {
            sheet = .edit(category.kind, category.id)
        } label: {
            VStack(spacing: 6) {
                IconImage(model.icon(for: category), size: 20)
                    .foregroundStyle(Palette.gold)

                Text(category.name)
                    .font(.system(size: 11))
                    .foregroundStyle(Palette.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: Self.tileHeight)
            .overlay(alignment: .bottom) {
                Capsule()
                    .fill(color ?? Palette.mist)
                    .frame(width: 24, height: 2)
                    .padding(.bottom, 7)
            }
            .background(tileBackground(isHidden: isHidden))
            .overlay {
                tileBorder(isHidden: isHidden)
            }
            .opacity(tileOpacity(isHidden: isHidden, isDragging: isDragging))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func tileBackground(isHidden: Bool) -> some View {
        if !isHidden {
            RoundedRectangle(cornerRadius: 16)
                .fill(Self.tileFill)
        }
    }

    @ViewBuilder
    func tileBorder(isHidden: Bool) -> some View {
        if isHidden {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.mist.opacity(0.4), style: Self.dash)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Palette.gold.opacity(0.22), lineWidth: 1)
        }
    }
}

private extension CategoryListView {
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

    static let tileHeight: CGFloat = 78
    static let addStroke = Palette.gold.opacity(0.55)
    static let dash = StrokeStyle(lineWidth: 1, dash: [4, 3])

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 4
    )

    static var tileFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func tileOpacity(
        isHidden: Bool,
        isDragging: Bool
    ) -> Double {
        if isDragging {
            return 0.35
        }

        return isHidden ? 0.6 : 1
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

private struct TileDrop: DropDelegate {
    @Binding var dragging: EntryCategory.ID?

    let target: EntryCategory.ID
    let model: CategoryListModel

    func dropEntered(info: DropInfo) {
        guard let dragging else {
            return
        }

        withAnimation(.snappy) {
            model.move(dragging, to: target)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        dragging = nil

        Task {
            await model.finishMoving()
        }

        return true
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
