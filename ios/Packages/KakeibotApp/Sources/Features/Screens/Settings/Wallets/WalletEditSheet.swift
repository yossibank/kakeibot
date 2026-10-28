import Core
import DesignSystem
import Store
import SwiftUI

public struct WalletEditSheet: View {
    @State private var model: WalletEditModel
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingHideChanges = false
    @State private var isEnteringAmount = false
    @State private var isEnteringValuation = false
    @State private var isEnteringLoanAmount = false
    @State private var isEditingIcon = false
    @State private var iconBottom: CGFloat = 0
    @State private var openValuationId: Valuation.ID?
    @State private var isConfirmingHide = false
    @State private var isConfirmingDelete = false
    @State private var isEditingPayment = false
    @State private var isAskingPayment = false
    @State private var leavesForEntries = false
    @State private var addedWallet: Wallet?

    @FocusState private var focus: Field?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.themeStyle.corner) private var corner

    private let onSave: (Wallet) -> Void
    private let onDelete: (Deletion) -> Void
    private let onHide: () -> Void
    private let onShowEntries: (() -> Void)?

    public init(
        model: WalletEditModel,
        onSave: @escaping (Wallet) -> Void = { _ in },
        onDelete: @escaping (Deletion) -> Void = { _ in },
        onHide: @escaping () -> Void = {},
        onShowEntries: (() -> Void)? = nil
    ) {
        _model = State(initialValue: model)

        self.onSave = onSave
        self.onDelete = onDelete
        self.onHide = onHide
        self.onShowEntries = onShowEntries
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
                        .zIndex(1)

                    SettingsDrawer("最初の残高", showsDone: false) {
                        closeAmount()
                    } content: {
                        VStack(spacing: 12) {
                            Keypad(calculator: model.calculator) {
                                closeAmount()
                            } onKey: { key in
                                model.press(key)
                            }

                            saveButton
                        }
                    }
                    .transition(.settingsDrawer)
                    .zIndex(1)
                }

                if isEnteringValuation {
                    amountDrawer(
                        "今の評価額",
                        calculator: model.valuation,
                        onPress: model.pressValuation,
                        onDismiss: closeValuation
                    ) {
                        Task {
                            await saveValuation()
                        }
                    } button: {
                        PrimaryButton("評価額を保存") {
                            Task {
                                await saveValuation()
                            }
                        }
                    }
                }

                if isEnteringLoanAmount {
                    amountDrawer(
                        "最初に借りた額",
                        calculator: model.loanAmount,
                        onPress: model.pressLoanAmount,
                        onDismiss: closeLoanAmount,
                        onDone: closeLoanAmount
                    ) {
                        saveButton
                    }
                }
            }
        }
        .iconEditorDrawer(
            isPresented: $isEditingIcon,
            model: model.icon,
            focus: $focus,
            textField: .text,
            below: iconBottom
        )
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .confirmsUnsavedHide(
            isHidden: model.isHidden,
            canSave: model.canSave,
            isPresented: $isConfirmingHideChanges
        ) {
            Task {
                await save(hiding: true)
            }
        } onDiscard: {
            Task {
                await setHidden(!model.isHidden)
            }
        }
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            discard()
        }
        .onChange(of: isConfirmingDiscard) {
            if !isConfirmingDiscard {
                leavesForEntries = false
            }
        }
        .confirmsWalletDelete(isPresented: $isConfirmingDelete) {
            Task {
                await delete()
            }
        }
        .confirmsWalletHide(
            balance: model.balance,
            isPresented: $isConfirmingHide
        ) {
            requestHide()
        }
        .onChange(of: model.kind) {
            focus = nil
        }
        .sheet(isPresented: $isEditingPayment) {
            closePayment()
        } content: {
            RecurringEditSheet(model: model.paymentModel(for: addedWallet?.id))
        }
        .confirmation(
            isPresented: $isAskingPayment,
            systemImage: "repeat",
            title: model.paymentQuestion,
            message: model.paymentQuestionNote,
            keepTitle: "あとで",
            confirmTitle: "決める",
            role: .suggestion,
            onKeep: finishAddedWallet
        ) {
            isEditingPayment = true
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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        preview

                        colorNote
                    }
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .global).maxY
                    } action: { maxY in
                        iconBottom = maxY
                    }

                    SettingsField(
                        "名前",
                        text: $model.name,
                        focus: $focus,
                        field: .name
                    )

                    kindChooser

                    balanceField

                    if model.showsValuation {
                        valuationField
                    }

                    if !rowItems.isEmpty {
                        SettingsRowList(items: rowItems) { panel in
                            open(panel)
                        }
                    }
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
        .padding(.horizontal, 20)
        .padding(.top, 20)
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
        SettingsEditHeader(
            title: title,
            isEditing: model.isEditing,
            isHidden: model.isHidden
        ) {
            close()
        } onHide: {
            toggleHidden()
        } onDelete: {
            focus = nil
            isConfirmingDelete = true
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
        HStack(spacing: 16) {
            Button {
                focus = nil
                isEditingIcon = true
            } label: {
                IconImage(model.icon.preview, size: 22)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 48, height: 48)
                    .background(
                        Palette.accent.opacity(.subtle),
                        in: .rect(cornerRadius: corner.radius(16))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: corner.radius(16))
                            .stroke(iconStroke, lineWidth: iconStrokeWidth)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        EditBadge()
                            .offset(x: 4, y: 4)
                    }
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(previewName)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(model.kind.title)
                    .textFont(.caption2)
                    .tracking(1)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text("最初の残高")
                    .textFont(.caption2)
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
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: model.icon.color) ?? Palette.subtext)
                .frame(width: 10, height: 10)

            Text("アイコンの色は、振り返りのグラフの色になります")
        }
        .textFont(.caption2)
        .foregroundStyle(Palette.subtext)
        .padding(.leading, 4)
    }

    var kindChooser: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("種類")

            LazyVGrid(columns: Self.kindColumns, spacing: 8) {
                ForEach(Wallet.Kind.allCases, id: \.self) { kind in
                    kindButton(kind)
                }
            }
        }
    }

    var balanceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("最初の残高")

            HStack(spacing: 12) {
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

                        EditBadge()
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 12)
                    .frame(height: 46)
                    .background(
                        Palette.panel,
                        in: .rect(cornerRadius: corner.radius(16))
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: corner.radius(16))
                            .stroke(amountStroke, lineWidth: 1)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            Text(balanceHint)
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .contentTransition(.opacity)
                .animation(.snappy, value: model.kind == .card)
        }
    }

    var valuationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsRowList(items: valuationItems) { panel in
                open(panel)
            }

            Text("値動きの分は、収入や支出に入れず、残高だけを合わせます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            if !model.valuations.isEmpty {
                valuationHistory
            }
        }
    }

    var valuationHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionTitle("これまでの評価額")
                .padding(.top, 12)

            ForEach(model.valuations) { valuation in
                SwipeRow(id: valuation.id, openId: $openValuationId) {
                    openValuationId = nil
                } onAction: {
                    Task {
                        await model.deleteValuation(valuation.id)
                    }
                } content: {
                    valuationRow(valuation)
                }
            }

            Text("横に払うと消せます。消すと、前の評価額から数え直します")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
        }
    }

    var signButton: some View {
        Button {
            model.isNegative.toggle()
        } label: {
            Image(systemName: signSymbol)
                .sansFont(.body, weight: .semibold)
                .foregroundStyle(signColor)
                .frame(width: 46, height: 46)
                .background(
                    signFill,
                    in: .rect(cornerRadius: corner.radius(16))
                )
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(16))
                        .stroke(signColor.opacity(0.6), lineWidth: 1)
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: model.isNegative)
    }

    func amountDrawer(
        _ title: String,
        calculator: AmountCalculator,
        onPress: @escaping (AmountCalculator.Key) -> Void,
        onDismiss: @escaping () -> Void,
        onDone: @escaping () -> Void,
        @ViewBuilder button: () -> some View
    ) -> some View {
        Group {
            Palette.scrim
                .opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
                .transition(.opacity)
                .zIndex(1)

            SettingsDrawer(title, showsDone: false) {
                onDone()
            } content: {
                VStack(spacing: 12) {
                    SettingsKeypadValue(calculator.amount)

                    Keypad(calculator: calculator) {
                        onDone()
                    } onKey: { key in
                        onPress(key)
                    }

                    button()
                }
            }
            .transition(.settingsDrawer)
            .zIndex(1)
        }
    }

    func valuationRow(_ valuation: Valuation) -> some View {
        let date = valuation.date

        return HStack {
            Text("\(String(date.year))/\(date.month)/\(date.day)")
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 8)

            Text(AmountText.text(valuation.amount))
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .card(cornerRadius: 16)
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
                .textFont(.footnote)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
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

    enum Panel: Hashable {
        case payment
        case valuation
        case loanAmount
        case entries
    }

    static let fade: CGFloat = 16

    static let kindColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    var title: String {
        model.isEditing ? "口座を編集" : "口座を追加"
    }

    var paymentItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .payment,
                systemImage: "repeat",
                title: model.paymentTitle,
                value: model.paymentText,
                isEmpty: model.payment == nil
            )
        ]
    }

    var loanAmountItem: SettingsRowList<Panel>.Item {
        .init(
            panel: .loanAmount,
            systemImage: "yensign.circle",
            title: "最初に借りた額",
            value: model.loanAmountText,
            detail: model.repaidText,
            isEmpty: model.loanAmount.amount == 0,
            isAmount: true
        )
    }

    var entriesItem: SettingsRowList<Panel>.Item {
        .init(
            panel: .entries,
            systemImage: "list.bullet",
            title: "出入りを見る",
            value: "記録",
            isEmpty: false
        )
    }

    var rowItems: [SettingsRowList<Panel>.Item] {
        let loan = model.showsLoanAmount ? [loanAmountItem] : []
        let payment = model.showsPayment ? paymentItems : []
        let entries = showsEntries ? [entriesItem] : []

        return payment + loan + entries
    }

    var showsEntries: Bool {
        onShowEntries != nil && model.isEditing
    }

    var valuationItems: [SettingsRowList<Panel>.Item] {
        let amount = isEnteringValuation
            ? model.valuation.amount
            : model.balance

        return [
            .init(
                panel: .valuation,
                systemImage: "chart.line.uptrend.xyaxis",
                title: "今の評価額",
                value: AmountText.text(amount),
                isEmpty: false,
                isAmount: true
            )
        ]
    }

    var previewName: String {
        model.name.isEmpty ? "名前" : model.name
    }

    var balanceHint: String {
        switch model.kind {
        case .card: "まだ引き落とされていない額を入れます。自動でマイナスにします"
        case .loan: "まだ返していない額を入れます。自動でマイナスにします"
        default: "記録を始める前の、いまの残高を入れます"
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

    var iconStroke: Color {
        isEditingIcon ? Palette.accent : Palette.outline
    }

    var iconStrokeWidth: CGFloat {
        isEditingIcon ? 2 : 1
    }

    var amountStroke: Color {
        isEnteringAmount ? Palette.accent : Palette.accent.opacity(.muted)
    }

    func open(_ panel: Panel) {
        switch panel {
        case .payment: isEditingPayment = true
        case .valuation: openValuation()
        case .loanAmount: openLoanAmount()
        case .entries: showEntries()
        }
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

    func openValuation() {
        focus = nil

        model.startValuation()

        withAnimation(.snappy) {
            isEnteringValuation = true
        }
    }

    func closeValuation() {
        withAnimation(.snappy) {
            isEnteringValuation = false
        }
    }

    func openLoanAmount() {
        focus = nil

        withAnimation(.snappy) {
            isEnteringLoanAmount = true
        }
    }

    func closeLoanAmount() {
        withAnimation(.snappy) {
            isEnteringLoanAmount = false
        }
    }

    func saveValuation() async {
        if await model.saveValuation() {
            closeValuation()
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

    func showEntries() {
        focus = nil

        if model.isChanged {
            isConfirmingDiscard = true
            leavesForEntries = true
        } else {
            onShowEntries?()
        }
    }

    func discard() {
        if leavesForEntries {
            onShowEntries?()
        } else {
            dismiss()
        }
    }

    func save(hiding: Bool = false) async {
        focus = nil

        guard let wallet = await model.save() else {
            return
        }

        guard !model.isEditing, model.asksPayment else {
            onSave(wallet)

            if hiding {
                guard await model.setHidden(!model.isHidden) else {
                    return
                }

                if model.isHidden {
                    onHide()
                }
            }

            dismiss()
            return
        }

        addedWallet = wallet
        isAskingPayment = true
    }

    func closePayment() {
        guard addedWallet == nil else {
            finishAddedWallet()
            return
        }

        Task {
            await model.loadPayment()
        }
    }

    func finishAddedWallet() {
        guard let addedWallet else {
            return
        }

        onSave(addedWallet)
        dismiss()
    }

    func toggleHidden() {
        focus = nil

        guard !model.needsHideConfirmation else {
            isConfirmingHide = true
            return
        }

        requestHide()
    }

    func requestHide() {
        guard model.isChanged else {
            Task {
                await setHidden(!model.isHidden)
            }

            return
        }

        isConfirmingHideChanges = true
    }

    func setHidden(_ isHidden: Bool) async {
        if await model.setHidden(isHidden) {
            if isHidden {
                onHide()
            }

            dismiss()
        }
    }

    func delete() async {
        if let deletion = await model.delete() {
            onDelete(deletion)
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
