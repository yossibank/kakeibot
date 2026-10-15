import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateEditSheet: View {
    @State private var model: TemplateEditModel
    @State private var panel: Panel?
    @State private var isConfirmingDiscard = false
    @State private var errorCount = 0

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss

    let onSave: (EntryTemplate) -> Void

    public init(
        model: TemplateEditModel,
        onSave: @escaping (EntryTemplate) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.onSave = onSave
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                content

                if let panel {
                    Color.black
                        .opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closePanel()
                        }
                        .transition(.opacity)

                    if panel == .memo {
                        memoCard
                            .padding(.horizontal, 14)
                            .frame(maxHeight: .infinity)
                            .transition(Self.memoTransition)
                    } else {
                        drawerView(panel)
                            .transition(Self.drawerTransition)
                    }
                }
            }
            .overlay(alignment: .top) {
                header
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
            }
            .overlay(alignment: .bottom) {
                if let errorMessage = model.errorMessage {
                    NoticeBanner(
                        errorMessage,
                        systemImage: "exclamationmark",
                        tone: .error
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: model.errorMessage)
            .sensoryFeedback(.error, trigger: errorCount)
            .background {
                Rectangle()
                    .fill(Palette.night)
                    .ignoresSafeArea()
                    .onTapGesture {
                        focus = nil
                    }
            }
            .preferredColorScheme(.dark)
            .sensoryFeedback(.selection, trigger: model.categoryId)
            .sensoryFeedback(.selection, trigger: model.walletId)
            .confirmsDiscard(
                when: model.isChanged,
                isPresented: $isConfirmingDiscard
            ) {
                dismiss()
            }
            .onChange(of: focus) {
                if focus == .name {
                    hidePanel()
                }
            }
            .task {
                await model.load()
            }
            .task(id: errorCount) {
                guard errorCount > 0 else {
                    return
                }

                guard await (try? Task.sleep(for: .seconds(3))) != nil else {
                    return
                }

                model.clearError()
            }
        }
    }
}

private extension TemplateEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            preview
            rows

            Text("金額を空にすると、使うときに入れる")
                .font(.caption2)
                .foregroundStyle(Palette.mist)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .padding(.top, -8)

            Spacer(minLength: 0)

            if model.isEditing {
                deleteButton
            } else {
                capsulePreview
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
    }

    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }
            .frame(width: 64, alignment: .leading)

            Spacer()

            Text(title)
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Button {
                Task {
                    await save()
                }
            } label: {
                Text("保存")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(saveColor)
                    .frame(minWidth: 64, minHeight: 44)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    var preview: some View {
        VStack(spacing: 14) {
            card

            Text("ホームでは、このカードで並ぶ")
                .font(.caption2)
                .tracking(1)
                .foregroundStyle(Palette.mist)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            EllipticalGradient(
                colors: [Palette.gold.opacity(0.16), .clear],
                center: .center,
                startRadiusFraction: 0,
                endRadiusFraction: 0.5
            )
        }
    }

    var card: some View {
        TemplateCard(
            icon: categoryIcon,
            detail: detail,
            size: .large
        ) {
            TextField(
                "名前",
                text: $model.name,
                prompt: Text("名前を入れる").foregroundStyle(Palette.dusk)
            )
            .font(TemplateCardSize.large.nameFont)
            .foregroundStyle(Palette.champagne)
            .tint(Palette.gold)
            .submitLabel(.done)
            .focused($focus, equals: .name)
            .onSubmit {
                focus = nil
            }
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(nameLine)
                    .frame(height: 1)
            }
        } amount: {
            Button {
                open(.amount)
            } label: {
                TemplateCardAmount(amount: model.amount, size: .large)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
        .shadow(color: Palette.gold.opacity(0.12), radius: 30)
        .background(alignment: .bottom) {
            Ellipse()
                .fill(.black.opacity(0.55))
                .frame(width: 260, height: 22)
                .blur(radius: 14)
                .offset(y: 26)
        }
    }

    var rows: some View {
        VStack(spacing: 0) {
            ForEach(Array(rowItems.enumerated()), id: \.offset) { index, item in
                rowButton(item)
                    .overlay(alignment: .top) {
                        if index > 0 {
                            Rectangle()
                                .fill(Palette.gold.opacity(0.1))
                                .frame(height: 1)
                        }
                    }
            }
        }
        .background(Self.cardFill.opacity(0.7), in: Self.rowsShape)
        .overlay {
            Self.rowsShape
                .stroke(Palette.gold.opacity(0.18), lineWidth: 1)
        }
    }

    var deleteButton: some View {
        Button {
            Task {
                await delete()
            }
        } label: {
            Text("このテンプレートを削除")
                .font(.subheadline)
                .foregroundStyle(Palette.rose)
                .frame(maxWidth: .infinity, minHeight: 46)
                .overlay {
                    Capsule()
                        .stroke(Palette.rose.opacity(0.45), lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    var capsulePreview: some View {
        HStack(spacing: 8) {
            Text("入力シートでは")
                .font(.caption2)
                .foregroundStyle(Palette.mist)

            HStack(spacing: 6) {
                IconImage(categoryIcon, size: 12)
                    .foregroundStyle(Palette.gold)

                Text(previewName)
                    .foregroundStyle(Palette.ink)

                Text(capsuleAmount)
                    .font(.system(size: 11, design: .serif))
                    .foregroundStyle(Palette.champagne)
            }
            .font(.system(size: 11))
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .frame(height: 30)
            .overlay {
                Capsule()
                    .stroke(Palette.gold.opacity(0.4), lineWidth: 1)
            }
        }
        .frame(minHeight: 46)
    }

    var memoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("メモ", systemImage: "square.and.pencil")
                    .font(.caption)
                    .foregroundStyle(Palette.gold)

                Spacer()

                Button("完了") {
                    closePanel()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.gold)
                .frame(minWidth: 44, minHeight: 32)
            }

            TextField(
                "メモ",
                text: $model.memo,
                prompt: Text("メモを書く").foregroundStyle(Palette.dusk),
                axis: .vertical
            )
            .lineLimit(1...4)
            .font(.subheadline)
            .foregroundStyle(Palette.ink)
            .tint(Palette.gold)
            .focused($focus, equals: .memo)
        }
        .padding(14)
        .background(Palette.drawer, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Palette.gold.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            focus = .memo
        }
    }

    func rowButton(_ item: RowItem) -> some View {
        let isAmount = item.panel == .amount && !item.isEmpty
        let font: Font = isAmount ? Self.amountFont : .subheadline
        let color = item.isEmpty ? Palette.dusk : Palette.champagne

        return Button {
            open(item.panel)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 13))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 28, height: 28)
                    .background(Palette.gold.opacity(0.1), in: Circle())

                Text(item.title)
                    .font(.subheadline)
                    .foregroundStyle(Palette.mist)

                Spacer(minLength: 12)

                Text(item.value)
                    .font(font)
                    .foregroundStyle(color)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Palette.gold.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func drawerView(_ panel: Panel) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(title(for: panel))
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.gold)

                Spacer()

                Button("完了") {
                    closePanel()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.gold)
                .frame(minWidth: 44, minHeight: 32)
            }

            drawerBody(panel)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background {
            Self.drawerShape
                .fill(Palette.drawer)
                .overlay {
                    Self.drawerShape
                        .stroke(Palette.gold.opacity(0.35), lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }

    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            Keypad(activeTax: model.calculator.taxNote?.rate) { key in
                model.press(key)
            }
        case .category:
            tileGrid(model.categories, columns: 5, spacing: 5) { category in
                categoryButton(category)
            }
            .padding(.bottom, 8)
        case .wallet:
            tileGrid(model.wallets, columns: 3, spacing: 8) { wallet in
                walletButton(wallet)
            }
            .padding(.bottom, 8)
        case .memo:
            EmptyView()
        }
    }

    func tileGrid<Item: Identifiable>(
        _ items: [Item],
        columns: Int,
        spacing: CGFloat,
        @ViewBuilder tile: @escaping (Item) -> some View
    ) -> some View {
        let rows = Self.rows(of: items, size: columns)

        return Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(rows.indices, id: \.self) { index in
                GridRow {
                    ForEach(rows[index]) { item in
                        tile(item)
                    }

                    ForEach(rows[index].count..<columns, id: \.self) { _ in
                        Color.clear
                            .gridCellUnsizedAxes(.vertical)
                    }
                }
            }
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isSelected = model.categoryId == category.id
        let color = isSelected ? Palette.champagne : Palette.mist

        return Button {
            model.categoryId = category.id
            closePanel()
        } label: {
            VStack(spacing: 4) {
                IconImage(model.icon(for: category), size: 17)

                Text(category.name)
                    .font(.system(size: 10))
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(
                tileFill(isSelected: isSelected),
                in: .rect(cornerRadius: 12)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tileStroke(isSelected: isSelected), lineWidth: 1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func walletButton(_ wallet: Wallet) -> some View {
        let isSelected = model.walletId == wallet.id
        let color = isSelected ? Palette.champagne : Palette.mist

        return Button {
            model.walletId = wallet.id
            closePanel()
        } label: {
            HStack(spacing: 6) {
                IconImage(model.icon(for: wallet), size: 13)

                Text(wallet.name)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 40)
            .background(tileFill(isSelected: isSelected), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tileStroke(isSelected: isSelected), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private extension TemplateEditSheet {
    enum Field: Hashable {
        case name
        case memo
    }

    enum Panel: Hashable {
        case amount
        case category
        case wallet
        case memo
    }

    struct RowItem {
        let panel: Panel
        let systemImage: String
        let title: String
        let value: String
        let isEmpty: Bool
    }

    static let rowsShape = RoundedRectangle(cornerRadius: 20)
    static let amountFont = Font.system(size: 20, design: .serif)

    static let drawerShape = UnevenRoundedRectangle(
        topLeadingRadius: 28,
        topTrailingRadius: 28
    )

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var drawerTransition: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }

    static var memoTransition: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }

    var title: String {
        let action = model.isEditing ? "編集" : "追加"
        return "\(model.typeName)テンプレートを\(action)"
    }

    var saveColor: Color {
        model.canSave ? Palette.gold : Palette.dusk
    }

    var categoryIcon: Icon? {
        model.selectedCategory.flatMap { model.icon(for: $0) }
    }

    var detail: String {
        let parts = [model.selectedCategory?.name, model.selectedWallet?.name]
        return parts.compactMap(\.self).joined(separator: "・")
    }

    var nameLine: Color {
        if model.errorMessage != nil, model.name.isEmpty {
            Palette.rose
        } else if focus == .name {
            Palette.gold
        } else {
            Palette.gold.opacity(0.45)
        }
    }

    var previewName: String {
        model.name.isEmpty ? "名前" : model.name
    }

    var capsuleAmount: String {
        model.amount.map { AmountText.text($0) } ?? "入力"
    }

    var amountValue: String {
        model.amount.map { AmountText.text($0) } ?? "毎回入れる"
    }

    var memoValue: String {
        model.memo.isEmpty ? "なし" : model.memo
    }

    var rowItems: [RowItem] {
        [
            RowItem(
                panel: .amount,
                systemImage: "yensign",
                title: "金額",
                value: amountValue,
                isEmpty: model.amount == nil
            ),
            RowItem(
                panel: .category,
                systemImage: "square.grid.2x2",
                title: "カテゴリ",
                value: model.selectedCategory?.name ?? "選ぶ",
                isEmpty: model.selectedCategory == nil
            ),
            RowItem(
                panel: .wallet,
                systemImage: "wallet.bifold",
                title: model.walletTitle,
                value: model.selectedWallet?.name ?? "選ぶ",
                isEmpty: model.selectedWallet == nil
            ),
            RowItem(
                panel: .memo,
                systemImage: "square.and.pencil",
                title: "メモ",
                value: memoValue,
                isEmpty: model.memo.isEmpty
            )
        ]
    }

    static func rows<Item>(
        of items: [Item],
        size: Int
    ) -> [[Item]] {
        stride(from: 0, to: items.count, by: size).map { start in
            Array(items[start..<min(start + size, items.count)])
        }
    }

    func title(for panel: Panel) -> String {
        switch panel {
        case .amount: "金額"
        case .category: "カテゴリ"
        case .wallet: model.walletTitle
        case .memo: "メモ"
        }
    }

    func tileFill(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.12) : Color.clear
    }

    func tileStroke(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.55) : Palette.gold.opacity(0.12)
    }

    func open(_ panel: Panel) {
        focus = nil

        withAnimation(.snappy) {
            self.panel = panel
        }
    }

    func hidePanel() {
        withAnimation(.snappy) {
            panel = nil
        }
    }

    func closePanel() {
        focus = nil
        hidePanel()
    }

    func close() {
        closePanel()

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() async {
        closePanel()
        try? await Task.sleep(for: .milliseconds(80))

        guard let template = await model.save() else {
            errorCount += 1
            return
        }

        onSave(template)
        dismiss()
    }

    func delete() async {
        if await model.delete() {
            dismiss()
        } else {
            errorCount += 1
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        TemplateEditSheet(
            model: TemplateEditModel(
                database: database,
                type: .expense
            )
        )
    }
}
