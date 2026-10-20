import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletEditSheet: View {
    @State private var model: WalletEditModel
    @State private var isConfirmingDiscard = false
    @State private var isEnteringAmount = false
    @State private var isConfirmingHide = false

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    private let onSave: (Wallet) -> Void

    public init(
        model: WalletEditModel,
        onSave: @escaping (Wallet) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        self.onSave = onSave
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .bottom) {
                content

                if isEnteringAmount {
                    Palette.scrim
                        .opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeAmount()
                        }
                        .transition(.opacity)

                    SettingsDrawer("最初の残高") {
                        closeAmount()
                    } content: {
                        VStack(spacing: 10) {
                            Keypad(activeTax: activeTax) { key in
                                model.press(key)
                            }

                            saveButton
                        }
                    }
                    .transition(.settingsDrawer)
                }
            }
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .confirmsWalletHide(
            balance: model.balance,
            isPresented: $isConfirmingHide
        ) {
            Task {
                await setHidden(true)
            }
        }
        .onChange(of: model.kind) {
            focus = nil
        }
        .task {
            await model.load()
        }
    }
}

private extension WalletEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        preview
                        colorNote
                    }

                    SettingsField(
                        "名前",
                        text: $model.name,
                        font: .body,
                        focus: $focus,
                        field: .name
                    )

                    kindChooser
                    balanceField

                    IconEditor(
                        model: model.icon,
                        focus: $focus,
                        textField: .text
                    )
                }
                .padding(.bottom, 8)
                .padding(.vertical, Self.fade)
            }
            .scrollIndicators(.hidden)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .scrollDismissesKeyboard(.interactively)

            saveButton
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
    }

    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            Text(title)
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            if model.isEditing {
                SettingsHideButton(isHidden: model.isHidden) {
                    toggleHidden()
                }
            } else {
                Color.clear
                    .frame(width: 44, height: 44)
            }
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
        HStack(spacing: 14) {
            IconImage(model.icon.preview, size: 22)
                .foregroundStyle(Palette.accent)
                .frame(width: 48, height: 48)
                .background(
                    Palette.accent.opacity(.subtle),
                    in: .rect(cornerRadius: corner.radius(14))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(14))
                        .stroke(Palette.outline, lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(previewName)
                    .font(.subheadline)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)

                Text(model.kind.title)
                    .font(.caption2)
                    .tracking(1)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("最初の残高")
                    .font(.caption2)
                    .foregroundStyle(Palette.subtext)

                Text(AmountText.text(model.initialBalance))
                    .displayFont(.headline)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(16)
        .card(cornerRadius: 20)
    }

    var colorNote: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(hex: model.icon.color) ?? Palette.subtext)
                .frame(width: 10, height: 10)

            Text("アイコンの色は、振り返りのグラフの色になります")
        }
        .font(.caption2)
        .foregroundStyle(Palette.subtext)
        .padding(.leading, 4)
    }

    var kindChooser: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("種類")

            LazyVGrid(columns: Self.kindColumns, spacing: 8) {
                ForEach(Wallet.Kind.allCases, id: \.self) { kind in
                    kindButton(kind)
                }
            }
        }
    }

    var balanceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("最初の残高")

            HStack(spacing: 10) {
                signButton

                Button {
                    openAmount()
                } label: {
                    HStack(spacing: 8) {
                        Text(AmountText.text(model.calculator.amount))
                            .displayFont(.headline)
                            .monospacedDigit()
                            .foregroundStyle(Palette.text)

                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(
                        Palette.panel,
                        in: .rect(cornerRadius: corner.radius(14))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: corner.radius(14))
                            .stroke(amountStroke, lineWidth: 1)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            Text(balanceHint)
                .font(.caption)
                .foregroundStyle(Palette.subtext)
                .contentTransition(.opacity)
                .animation(.snappy, value: model.kind == .card)
        }
    }

    var signButton: some View {
        Button {
            model.isNegative.toggle()
        } label: {
            Image(systemName: signSymbol)
                .font(.sans(.body, weight: .semibold))
                .foregroundStyle(signColor)
                .frame(width: 46, height: 46)
                .background(
                    signFill,
                    in: .rect(cornerRadius: corner.radius(14))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(14))
                        .stroke(signColor.opacity(0.6), lineWidth: 1)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: model.isNegative)
    }

    func kindButton(_ kind: Wallet.Kind) -> some View {
        let isSelected = model.kind == kind
        let textColor = isSelected ? Palette.accentStrong : Palette.subtext
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)

        return Button {
            model.kind = kind
        } label: {
            Text(kind.title)
                .font(.footnote)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(fill, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(stroke, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

private extension WalletEditSheet {
    enum Field: Hashable {
        case name
        case text
    }

    static let fade: CGFloat = 16

    static let kindColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    var title: String {
        model.isEditing ? "口座を編集" : "口座を追加"
    }

    var previewName: String {
        model.name.isEmpty ? "名前" : model.name
    }

    var balanceHint: String {
        if model.kind == .card {
            "カードは、まだ引き落とされていない額をマイナスで入れます"
        } else {
            "記録を始める前の、いまの残高を入れます"
        }
    }

    var signSymbol: String {
        model.isNegative ? "minus" : "plus"
    }

    var signColor: Color {
        model.isNegative ? Palette.rose : Palette.accent
    }

    var signFill: Color {
        signColor.opacity(0.1)
    }

    var amountStroke: Color {
        isEnteringAmount ? Palette.accent : Palette.accent.opacity(.muted)
    }

    var activeTax: AmountCalculator.TaxRate? {
        model.calculator.taxNote?.rate
    }

    func openAmount() {
        focus = nil

        withAnimation(.snappy) {
            isEnteringAmount = true
        }
    }

    func closeAmount() {
        withAnimation(.snappy) {
            isEnteringAmount = false
        }
    }

    func close() {
        focus = nil

        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func save() async {
        focus = nil

        guard let wallet = await model.save() else {
            return
        }

        onSave(wallet)
        dismiss()
    }

    func toggleHidden() {
        focus = nil

        guard !model.needsHideConfirmation else {
            isConfirmingHide = true
            return
        }

        Task {
            await setHidden(!model.isHidden)
        }
    }

    func setHidden(_ isHidden: Bool) async {
        if await model.setHidden(isHidden) {
            dismiss()
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        WalletEditSheet(model: WalletEditModel(database: database))
    }
}
