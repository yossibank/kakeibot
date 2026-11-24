import Core
import DesignSystem
import Store
import SwiftUI

public struct EntrySheet: View {
    @State var model: EntryModel
    @State var deck: EntryDeck
    @State var deckEdge: Edge = .trailing
    @State var isEditingMemo = false
    @State var categoryPage: Int? = 0
    @State var sheet: Sheet?
    @State var addedWallet: AddedWallet?
    @State var reloadsWallets = false
    @State var categoryMenu: CategoryMenu?
    @State var sheetWidth: CGFloat = 0
    @State var panelHeight: CGFloat = 0
    @State var slipGrowth: CGFloat = 0
    @State var bottomInset: CGFloat = 0
    @State var deletion: Deletion?
    @State var hiddenCategory: EntryModel.HiddenCategory?
    @State var receipt = EntryReceiptFlow()
    @State var voice = EntryVoiceFlow()

    @Environment(\.themeStyle.corner) var corner
    @Environment(\.isPro) var isPro
    @Environment(\.canScanReceipt) var canScanReceipt
    @Environment(\.openURL) var openURL

    @State private var isConfirmingDiscard = false
    @State private var notice: EntryNoticeModel

    @FocusState private var isMemoFocused: Bool

    @Environment(\.dismiss) private var dismiss

    private let onChange: (EntryChange) -> Void
    private let startsReceipt: Bool

    public init(
        model: EntryModel,
        startsReceipt: Bool = false,
        onChange: @escaping (EntryChange) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)
        _deck = State(initialValue: EntryDeck.start(for: model.state.type))
        _notice = State(initialValue: model.newNoticeModel())

        self.onChange = onChange
        self.startsReceipt = startsReceipt
    }

    public var body: some View {
        FloatingInputReader { proxy in
            ZStack(alignment: .top) {
                fittedContent(in: proxy.size.height)
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
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.bottom
            } action: { inset in
                bottomInset = inset
            }
            .haptic(
                .impact(weight: .medium),
                trigger: categoryMenu
            ) { _, menu in
                menu != nil
            }
            .onChange(of: voice.isActive) {
                if voice.isActive {
                    show(.amount)
                }
            }
            .haptic(.impact(weight: .light), trigger: voice.startCount)
            .haptic(.impact(weight: .light), trigger: voice.endCount)
            .errorBanner(
                model.state.errorNotice,
                bottom: bannerBottom
            ) {
                model.state.errorNotice.clear()
            }
            .deletionNotice($deletion, bottom: bannerBottom) { deletion in
                Task {
                    await model.restore(deletion)
                    await model.reloadWallets()
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
            .backdrop()
            .modifier(
                EntryDiscardGuard(
                    isPresented: $isConfirmingDiscard,
                    model: model
                ) {
                    dismiss()
                }
            )
            .sheet(item: $sheet, onDismiss: reloadAfterSheet) { sheet in
                sheetContent(for: sheet)
            }
            .task {
                await load()

                if startsReceipt, showsReceiptButton {
                    withAnimation(.snappy) {
                        receipt.start(for: model, isPro: isPro)
                    }
                }
            }
            .task {
                await model.observeHistory()
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
                PrimaryButton(model.output.saveTitle) {
                    guard !opensKeypadOnSave else {
                        show(.amount)
                        return
                    }

                    Task {
                        await save()
                    }
                }
                .disabled(!model.output.canSave && !opensKeypadOnSave)

                if model.output.isEditing {
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
                        isEnabled: model.output.canSave
                    ) {
                        Task {
                            await saveAndContinue()
                        }
                    }
                }
            }
        }
    }

    func editMemo(_ isEditing: Bool) {
        if !isEditing {
            isMemoFocused = false
        }

        withAnimation(.snappy(duration: 0.25)) {
            isEditingMemo = isEditing
        }
    }

    func close() {
        if model.output.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
    }

    func delete() async {
        guard let change = await model.delete() else {
            return
        }

        model.state.isClosing = true
        onChange(change)
        dismiss()
    }
}

extension EntrySheet {
    nonisolated static let coordinateSpace = "EntrySheet"

    static let menuInset: CGFloat = 12
    static let liftInset: CGFloat = 12
    static let saveHeight: CGFloat = 56

    static var menuTransition: AnyTransition {
        .scale(scale: 0.92, anchor: .bottom).combined(with: .opacity)
    }

    var today: LocalDate {
        LocalDate(Date(), in: .current)
    }

    init(
        model: EntryModel,
        deck: EntryDeck
    ) {
        self.init(model: model)

        _deck = State(initialValue: deck)
    }
}

private extension EntrySheet {
    var content: some View {
        VStack(spacing: 12) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 16)

            VStack(spacing: 0) {
                summary

                deckPanel
                    .padding(.horizontal, 8)
                    .padding(.bottom, bottomGap)
            }
            .padding(.horizontal, 8)
            .ignoresSafeArea(edges: .bottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    func fittedContent(in height: CGFloat) -> some View {
        if height > 0, height < fitHeight {
            ScrollView {
                content
                    .frame(height: fitHeight)
            }
            .scrollIndicators(.hidden)
        } else {
            content
        }
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
            .frame(width: Self.continueWidth, height: Self.saveHeight)
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

    func recordAgain() async {
        await model.recordAgain()
        showSelectedCategory()
    }
}

private extension EntrySheet {
    static let continueWidth: CGFloat = 64
    static let fitBase: CGFloat = 692

    var bottomGap: CGFloat {
        bottomInset > 0 ? 20 : 8
    }

    var fitHeight: CGFloat {
        Self.fitBase + bottomGap - bottomInset
    }

    var bannerBottom: CGFloat {
        panelHeight + bottomGap - bottomInset + 4
    }

    var opensKeypadOnSave: Bool {
        deck != .amount && !model.output.isEditing && model.output.amount <= 0
    }

    func load() async {
        if !model.output.isLoaded {
            await model.load()

            deck = EntryDeck.start(for: model.state.type)
        }

        showSelectedCategory()
    }

    func save() async {
        guard let change = await model.save() else {
            return
        }

        model.state.isClosing = true
        onChange(change)
        dismiss()
    }

    func saveAndContinue() async {
        guard let change = await model.save() else {
            return
        }

        await model.startNext()
        notice.show(change)
        show(EntryDeck.start(for: model.state.type))
    }
}

#Preview {
    let database = try? AppDatabase.inMemory()
    let today = LocalDate(Date(), in: .current)

    if let database {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())

        EntrySheet(model: EntryModel(database: database, clock: .system, date: today))
    }
}
