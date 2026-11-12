import Core
import DesignSystem
import Store
import SwiftUI

public struct EntrySheet: View {
    @State var model: EntryModel
    @State var isEnteringAmount: Bool
    @State var isFormDeferred: Bool
    @State var categoryPage: Int? = 0
    @State var sheet: Sheet?
    @State var categoryMenu: CategoryMenu?
    @State var sheetWidth: CGFloat = 0
    @State var drawerHeight: CGFloat = 0
    @State var deletion: Deletion?
    @State var hiddenCategory: EntryModel.HiddenCategory?
    @State var receipt = EntryReceiptFlow()
    @State var voice = EntryVoiceFlow()

    @Environment(\.themeStyle.corner) var corner
    @Environment(\.isPro) var isPro
    @Environment(\.canScanReceipt) var canScanReceipt
    @Environment(\.openURL) var openURL

    @State private var isEditingMemo = false
    @State private var isConfirmingDiscard = false
    @State private var notice: EntryNoticeModel

    @FocusState private var isMemoFocused: Bool

    @Environment(\.dismiss) private var dismiss

    private let onChange: (EntryChange) -> Void

    public init(
        model: EntryModel,
        onChange: @escaping (EntryChange) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        _isEnteringAmount = State(initialValue: model.opensKeypad)
        _isFormDeferred = State(initialValue: model.opensKeypad)
        _notice = State(initialValue: EntryNoticeModel(database: model.database))

        self.onChange = onChange
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .top) {
                content
                    .ignoresSafeArea(.keyboard)
                    .floatingInput(isPresented: isEditingMemo) {
                        editMemo(false)
                    } card: {
                        EntryMemoCard(model: model, isFocused: $isMemoFocused) {
                            editMemo(false)
                        }
                    }

                if let categoryMenu {
                    categoryMenuLayer(categoryMenu)
                }

                receiptLayer

                voiceNoticeLayer(bottom: bannerBottom)
            }
            .coordinateSpace(.named(Self.coordinateSpace))
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                sheetWidth = width
            }
            .haptic(
                .impact(weight: .medium),
                trigger: categoryMenu
            ) { _, menu in
                menu != nil
            }
            .haptic(.impact(weight: .light), trigger: voice.startCount)
            .haptic(.impact(weight: .light), trigger: voice.endCount)
            .errorBanner(
                model.errorNotice,
                bottom: bannerBottom
            ) {
                model.errorNotice.clear()
            }
            .deletionNotice($deletion, bottom: bannerBottom) { deletion in
                Task {
                    await model.restore(deletion)
                }
            }
            .settingsHideNotice($hiddenCategory, bottom: bannerBottom) { hidden in
                Task {
                    await model.showCategory(hidden)
                    showSelectedCategory()
                }
            }
            .entryNotice(
                notice,
                above: bannerBottom - 12,
                clearsOnTap: false
            )
            .onChange(of: notice.notice) {
                if notice.notice == .undone {
                    Task {
                        await model.reloadWallets()
                    }
                }
            }
            .proOffer(receipt.offer, presentsInSheet: true) {
                receipt.closeOffer()
            } onUnlock: {
                receipt.closeOffer()
            }
            .fullScreenCover(isPresented: isScanningReceipt) {
                receiptCamera
            }
            .background {
                Backdrop()
                    .ignoresSafeArea()
            }
            .modifier(
                EntryDiscardGuard(
                    isPresented: $isConfirmingDiscard,
                    model: model
                ) {
                    dismiss()
                }
            )
            .sheet(item: $sheet, onDismiss: reloadCategories) { sheet in
                sheetContent(for: sheet)
            }
            .task {
                await load()
            }
            .task {
                await model.observeHistory()
            }
            .task {
                await revealForm()
            }
            .task {
                await voice.checkAvailability()
            }
            .onDisappear {
                Task {
                    await voice.cancel()
                }
            }
        }
    }
}

extension EntrySheet {
    var saveButtons: some View {
        EntryLiveSlot {
            HStack(spacing: 8) {
                EntrySaveButton(label: model.saveLabel(today: today)) {
                    guard !opensKeypadOnSave else {
                        setEnteringAmount(true)
                        return
                    }

                    Task {
                        await save()
                    }
                }
                .disabled(!model.canSave && !opensKeypadOnSave)

                if model.isEditing {
                    sideButton(
                        "もう一度",
                        systemImage: "doc.on.doc",
                        isEnabled: true
                    ) {
                        Task {
                            await recordAgain()
                        }
                    }
                } else {
                    sideButton(
                        "続けて",
                        systemImage: "plus.square.on.square",
                        isEnabled: model.canSave
                    ) {
                        Task {
                            await saveAndContinue()
                        }
                    }
                }
            }
        }
    }

    func close() {
        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func delete() async {
        guard let change = await model.delete() else {
            return
        }

        model.isClosing = true
        onChange(change)
        dismiss()
    }
}

extension EntrySheet {
    nonisolated static let coordinateSpace = "EntrySheet"

    static let menuInset: CGFloat = 12
    static let liftInset: CGFloat = 12

    static var menuTransition: AnyTransition {
        .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
    }

    var today: LocalDate {
        LocalDate(Date(), in: .current)
    }
}

private extension EntrySheet {
    var content: some View {
        VStack(spacing: 12) {
            header

            ScrollView {
                form
                    .padding(.vertical, Self.fade)
                    .padding(.horizontal, Self.liftInset)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .padding(.horizontal, -Self.liftInset)

            VStack(spacing: 12) {
                EntryDetailBand(
                    model: model,
                    today: today,
                    onWallet: {
                        open(.wallet(.source))
                    },
                    onFee: {
                        enterFee()
                    },
                    onDate: {
                        open(.date)
                    },
                    onMemo: {
                        editMemo(true)
                    }
                )

                saveButtons
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .contentShape(.rect)
        .onTapGesture {
            setEnteringAmount(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            if isEnteringAmount {
                keypadDrawer
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    var form: some View {
        VStack(spacing: 24) {
            dial

            if model.type == .transfer {
                transferArea
            } else {
                categoryArea
            }
        }
    }

    var dial: some View {
        EntryDialFace(model: model, levels: voiceLevels, preview: voice.preview) {
            open(.items)
        }
        .onTapGesture {
            tapDial()
        }
        .frame(maxWidth: .infinity)
    }

    func sideButton(
        _ title: String,
        systemImage: String,
        isEnabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .sansFont(.body)

                Text(title)
                    .textFont(.caption2, weight: .semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(Palette.accent)
            .frame(width: Self.continueWidth, height: 56)
            .overlay {
                Capsule()
                    .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }

    func revealForm() async {
        guard isFormDeferred else {
            return
        }

        try? await Task.sleep(for: Self.formRevealDelay)
        isFormDeferred = false
    }

    func recordAgain() async {
        await model.recordAgain()
        showSelectedCategory()
    }
}

private extension EntrySheet {
    static let fade: CGFloat = 20
    static let formRevealDelay: Duration = .milliseconds(450)
    static let continueWidth: CGFloat = 64

    var bannerBottom: CGFloat {
        isEnteringAmount ? drawerHeight + 12 : 12
    }

    var opensKeypadOnSave: Bool {
        !isEnteringAmount && !model.isEditing && model.amount <= 0
    }

    func editMemo(_ isEditing: Bool) {
        setEnteringAmount(false)

        if !isEditing {
            isMemoFocused = false
        }

        withAnimation(.snappy(duration: 0.25)) {
            isEditingMemo = isEditing
        }
    }

    func load() async {
        if !model.isLoaded {
            await model.load()
            isEnteringAmount = model.opensKeypad
        }

        showSelectedCategory()
    }

    func save() async {
        guard let change = await model.save() else {
            return
        }

        model.isClosing = true
        onChange(change)
        dismiss()
    }

    func saveAndContinue() async {
        guard let change = await model.save() else {
            return
        }

        await model.startNext()
        notice.show(change)
        setEnteringAmount(model.startsWithAmount)
    }
}

#Preview {
    let database = try? AppDatabase.inMemory()
    let today = LocalDate(Date(), in: .current)

    if let database {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        EntrySheet(model: EntryModel(database: database, date: today))
    }
}
