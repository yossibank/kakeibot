import Core
import DesignSystem
import Store
import SwiftUI

public struct TemplateEditSheet: View {
    @State private var model: TemplateEditModel
    @State private var panel: Panel?
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
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                content
                    .ignoresSafeArea(keyboardRegions)

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
                            .transition(.settingsDrawer)
                    }
                }
            }
            .overlay(alignment: .top) {
                header
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
            }
            .errorBanner(model.errorNotice) {
                model.errorNotice.clear()
            }
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
        }
    }
}

private extension TemplateEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(spacing: 16) {
                    preview

                    VStack(alignment: .leading, spacing: 8) {
                        rows

                        Text("金額を空にすると、使うときに入れられます")
                            .font(.caption2)
                            .foregroundStyle(Palette.mist)
                            .padding(.leading, 6)
                    }

                    if !model.isEditing {
                        capsulePreview
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)

            saveButton
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
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Group {
                if model.isEditing {
                    RingButton(
                        systemImage: "trash",
                        style: .destructive,
                        label: "削除"
                    ) {
                        Task {
                            await delete()
                        }
                    }
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
            .frame(width: 64, alignment: .trailing)
        }
    }

    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            Task {
                await save()
            }
        }
        .disabled(!model.canSave)
    }

    var preview: some View {
        VStack(spacing: 14) {
            card

            Text("ホームでは、このカードで並びます")
                .font(.caption2)
                .tracking(1)
                .foregroundStyle(Palette.mist)
        }
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background {
            EllipticalGradient(
                colors: [Palette.gold.opacity(.soft), .clear],
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
        .shadow(color: Palette.gold.opacity(.subtle), radius: 30)
        .background(alignment: .bottom) {
            Ellipse()
                .fill(.black.opacity(0.55))
                .frame(width: 260, height: 22)
                .blur(radius: 14)
                .offset(y: 26)
        }
    }

    var rows: some View {
        SettingsRowList(items: rowItems) { panel in
            open(panel)
        }
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
                    .font(.serif(.caption))
                    .foregroundStyle(Palette.champagne)
            }
            .font(.sans(.caption))
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, 8)
            .padding(.trailing, 12)
            .frame(height: 30)
            .overlay {
                Capsule()
                    .stroke(Palette.gold.opacity(.muted), lineWidth: 1)
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

                RingButton(systemImage: "checkmark", style: .prominent) {
                    closePanel()
                }
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
                .stroke(Palette.outline, lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
        .task {
            focus = .memo
        }
    }

    func drawerView(_ panel: Panel) -> some View {
        SettingsDrawer(title(for: panel)) {
            closePanel()
        } content: {
            drawerBody(panel)
        }
    }

    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            VStack(spacing: 10) {
                Keypad(activeTax: model.calculator.taxNote?.rate) { key in
                    model.press(key)
                }

                saveButton
            }
        case .category:
            SettingsTileGrid(
                items: model.categories,
                columns: 5,
                spacing: 5
            ) { category in
                SettingsCategoryTile(
                    category: category,
                    icon: model.icon(for: category),
                    isSelected: model.categoryId == category.id
                ) {
                    model.categoryId = category.id
                    closePanel()
                }
            }
            .padding(.bottom, 8)
        case .tag:
            tagChooser
                .padding(.bottom, 8)
        case .wallet:
            SettingsTileGrid(
                items: model.wallets,
                columns: 3,
                spacing: 8
            ) { wallet in
                SettingsWalletTile(
                    wallet: wallet,
                    icon: model.icon(for: wallet),
                    isSelected: model.walletId == wallet.id
                ) {
                    model.walletId = wallet.id
                    closePanel()
                }
            }
            .padding(.bottom, 8)
        case .memo:
            EmptyView()
        }
    }

    @ViewBuilder
    var tagChooser: some View {
        if model.tags.isEmpty {
            Text("このカテゴリにタグはありません。カテゴリの編集で足せます")
                .font(.caption)
                .foregroundStyle(Palette.mist)
                .frame(maxWidth: .infinity, minHeight: 54)
        } else {
            TagLine(tagItems, selection: model.tagId) { id in
                model.toggleTag(id)
            }
        }
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
        case tag
        case wallet
        case memo
    }

    static var memoTransition: AnyTransition {
        .scale(scale: 0.95).combined(with: .opacity)
    }

    var title: String {
        let action = model.isEditing ? "編集" : "追加"
        return "\(model.typeName)テンプレートを\(action)"
    }

    var keyboardRegions: SafeAreaRegions {
        panel == .memo ? .keyboard : []
    }

    var categoryIcon: Icon? {
        model.selectedCategory.flatMap { model.icon(for: $0) }
    }

    var detail: String {
        let parts = [
            model.selectedCategory?.name,
            model.selectedTag?.name,
            model.selectedWallet?.name
        ]

        return parts.compactMap(\.self).joined(separator: "・")
    }

    var tagItems: [TagLine<EntryTag.ID>.Item] {
        model.tags.map { TagLine.Item(id: $0.id, name: $0.name) }
    }

    var nameLine: Color {
        if model.errorNotice.message != nil, model.name.isEmpty {
            Palette.rose
        } else if focus == .name {
            Palette.gold
        } else {
            Palette.gold.opacity(.medium)
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

    var rowItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .amount,
                systemImage: "yensign",
                title: "金額",
                value: amountValue,
                isEmpty: model.amount == nil,
                isAmount: true
            ),
            .init(
                panel: .category,
                systemImage: "square.grid.2x2",
                title: "カテゴリ",
                value: model.selectedCategory?.name ?? "選ぶ",
                isEmpty: model.selectedCategory == nil
            ),
            .init(
                panel: .tag,
                systemImage: "tag",
                title: "タグ",
                value: model.selectedTag?.name ?? "なし",
                isEmpty: model.selectedTag == nil
            ),
            .init(
                panel: .wallet,
                systemImage: "wallet.bifold",
                title: model.walletTitle,
                value: model.selectedWallet?.name ?? "選ぶ",
                isEmpty: model.selectedWallet == nil
            ),
            .init(
                panel: .memo,
                systemImage: "square.and.pencil",
                title: "メモ",
                value: memoValue,
                isEmpty: model.memo.isEmpty
            )
        ]
    }

    func title(for panel: Panel) -> String {
        switch panel {
        case .amount: "金額"
        case .category: "カテゴリ"
        case .tag: "タグ"
        case .wallet: model.walletTitle
        case .memo: "メモ"
        }
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
