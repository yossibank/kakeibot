import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateEditSheet: View {
    @State private var model: TemplateEditModel
    @State private var drawer: Drawer?
    @State private var isConfirmingDiscard = false

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
        ZStack(alignment: .bottom) {
            content
                .ignoresSafeArea(.keyboard)

            if let drawer {
                Color.black
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeDrawer()
                    }
                    .transition(.opacity)

                drawerView(drawer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
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
                closeDrawer()
            }
        }
        .task {
            await model.load()
        }
    }
}

private extension TemplateEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            header
            preview
            rows

            Text("金額を空にすると、使うときに入れる")
                .font(.caption2)
                .foregroundStyle(Palette.mist)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 6)
                .padding(.top, -8)

            if let errorMessage = model.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(Palette.rose)
            }

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
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
    }

    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            Text(title)
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Button("保存") {
                Task {
                    await save()
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(saveColor)
            .frame(minWidth: 44, minHeight: 44)
            .disabled(!model.canSave)
        }
    }

    var preview: some View {
        VStack(spacing: 12) {
            card

            Text("ホームでは、このカードで並ぶ")
                .font(.caption2)
                .tracking(1)
                .foregroundStyle(Palette.mist)
        }
        .padding(.vertical, 10)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                IconImage(categoryIcon, size: 22)
                    .foregroundStyle(Palette.gold)
                    .frame(width: 46, height: 46)
                    .overlay {
                        Circle()
                            .stroke(Palette.gold.opacity(0.45), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(detail)
                        .font(.caption2)
                        .tracking(2)
                        .foregroundStyle(Palette.mist)
                        .lineLimit(1)

                    TextField(
                        "名前",
                        text: $model.name,
                        prompt: Text("名前を入れる").foregroundStyle(Palette.dusk)
                    )
                    .font(.title3)
                    .foregroundStyle(Palette.champagne)
                    .tint(Palette.gold)
                    .submitLabel(.done)
                    .focused($focus, equals: .name)
                    .onSubmit {
                        focus = nil
                    }
                    .padding(.bottom, 3)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(nameLine)
                            .frame(height: 1)
                    }
                }
            }

            HStack(alignment: .firstTextBaseline) {
                Button {
                    open(.amount)
                } label: {
                    cardAmount
                }
                .buttonStyle(.plain)

                Spacer(minLength: 8)

                Text(cardHint)
                    .font(.caption2)
                    .tracking(1)
                    .foregroundStyle(Palette.gold)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 18)
        .frame(maxWidth: 290)
        .background(Self.cardFill, in: Self.cardShape)
        .overlay {
            Self.cardShape
                .stroke(Palette.gold.opacity(0.55), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.55), radius: 20, y: 16)
    }

    @ViewBuilder
    var cardAmount: some View {
        if let amount = model.amount {
            Text(AmountText.text(amount))
                .font(.system(size: 34, weight: .medium, design: .serif))
                .monospacedDigit()
                .foregroundStyle(Palette.champagne)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else {
            Text("毎回入れる")
                .font(.title3)
                .foregroundStyle(Palette.dusk)
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

    func rowButton(_ item: RowItem) -> some View {
        let isAmount = item.drawer == .amount && !item.isEmpty
        let font: Font = isAmount ? Self.amountFont : .subheadline
        let color = item.isEmpty ? Palette.dusk : Palette.champagne

        return Button {
            open(item.drawer)
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

    func drawerView(_ drawer: Drawer) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(drawer.title)
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.gold)

                Spacer()

                Button("完了") {
                    closeDrawer()
                }
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Palette.gold)
                .frame(minWidth: 44, minHeight: 32)
            }

            drawerBody(drawer)
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
    func drawerBody(_ drawer: Drawer) -> some View {
        switch drawer {
        case .amount:
            Keypad(activeTax: model.calculator.taxNote?.rate) { key in
                model.press(key)
            }
        case .category:
            LazyVGrid(columns: Self.categoryColumns, spacing: 5) {
                ForEach(model.categories) { category in
                    categoryButton(category)
                }
            }
            .padding(.bottom, 8)
        case .wallet:
            LazyVGrid(columns: Self.walletColumns, spacing: 8) {
                ForEach(model.wallets) { wallet in
                    walletButton(wallet)
                }
            }
            .padding(.bottom, 8)
        case .memo:
            memoField
        }
    }

    var memoField: some View {
        TextField(
            "メモ",
            text: $model.memo,
            prompt: Text("メモ（なくてもよい）").foregroundStyle(Palette.dusk)
        )
        .font(.body)
        .foregroundStyle(Palette.ink)
        .tint(Palette.gold)
        .submitLabel(.done)
        .focused($focus, equals: .memo)
        .onSubmit {
            closeDrawer()
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Palette.night, in: .rect(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(Palette.gold, lineWidth: 1)
        }
        .padding(.bottom, 8)
        .onAppear {
            focus = .memo
        }
    }

    func categoryButton(_ category: EntryCategory) -> some View {
        let isSelected = model.categoryId == category.id
        let color = isSelected ? Palette.champagne : Palette.mist

        return Button {
            model.categoryId = category.id
            closeDrawer()
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
            closeDrawer()
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

    enum Drawer: Hashable {
        case amount
        case category
        case wallet
        case memo

        var title: String {
            switch self {
            case .amount: "金額"
            case .category: "カテゴリ"
            case .wallet: "財布"
            case .memo: "メモ"
            }
        }
    }

    struct RowItem {
        let drawer: Drawer
        let systemImage: String
        let title: String
        let value: String
        let isEmpty: Bool
    }

    static let cardShape = RoundedRectangle(cornerRadius: 26)
    static let rowsShape = RoundedRectangle(cornerRadius: 20)
    static let amountFont = Font.system(size: 20, design: .serif)

    static let drawerShape = UnevenRoundedRectangle(
        topLeadingRadius: 28,
        topTrailingRadius: 28
    )

    static let categoryColumns = Array(
        repeating: GridItem(.flexible(), spacing: 5),
        count: 5
    )

    static let walletColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    static var cardFill: LinearGradient {
        LinearGradient(
            colors: [Palette.cardTop, Palette.cardBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
        focus == .name ? Palette.gold : Palette.gold.opacity(0.45)
    }

    var cardHint: String {
        model.amount == nil ? "押すと金額を入れる" : "押すとすぐ記録"
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
                drawer: .amount,
                systemImage: "yensign",
                title: "金額",
                value: amountValue,
                isEmpty: model.amount == nil
            ),
            RowItem(
                drawer: .category,
                systemImage: "square.grid.2x2",
                title: "カテゴリ",
                value: model.selectedCategory?.name ?? "選ぶ",
                isEmpty: model.selectedCategory == nil
            ),
            RowItem(
                drawer: .wallet,
                systemImage: "wallet.bifold",
                title: "財布",
                value: model.selectedWallet?.name ?? "選ぶ",
                isEmpty: model.selectedWallet == nil
            ),
            RowItem(
                drawer: .memo,
                systemImage: "square.and.pencil",
                title: "メモ",
                value: memoValue,
                isEmpty: model.memo.isEmpty
            )
        ]
    }

    func tileFill(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.12) : Color.clear
    }

    func tileStroke(isSelected: Bool) -> Color {
        isSelected ? Palette.gold.opacity(0.55) : Palette.gold.opacity(0.12)
    }

    func open(_ drawer: Drawer) {
        if drawer != .memo {
            focus = nil
        }

        withAnimation(.snappy) {
            self.drawer = drawer
        }
    }

    func closeDrawer() {
        focus = nil

        withAnimation(.snappy) {
            drawer = nil
        }
    }

    func close() {
        closeDrawer()

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() async {
        closeDrawer()

        guard let template = await model.save() else {
            return
        }

        onSave(template)
        dismiss()
    }

    func delete() async {
        if await model.delete() {
            dismiss()
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
