import Core
import DesignSystem
import Store
import SwiftUI

public struct EntrySheet: View {
    @State var model: EntryModel
    @State var isEnteringAmount: Bool
    @State var categoryPage: Int? = 0
    @State var sheet: Sheet?
    @State var categoryMenu: CategoryMenu?
    @State var pressingCategory: EntryCategory.ID?
    @State var sheetWidth: CGFloat = 0
    @State var drawerHeight: CGFloat = 0
    @State var deletion: Deletion?

    @Environment(\.themeStyle.corner) var corner

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
            .background {
                Backdrop()
                    .ignoresSafeArea()
            }
            .confirmsDiscard(
                when: model.isChanged,
                isPresented: $isConfirmingDiscard
            ) {
                dismiss()
            }
            .sheet(item: $sheet, onDismiss: reloadCategories) { sheet in
                sheetContent(for: sheet)
            }
            .task {
                await load()
            }
            .task {
                await model.observeHistory()
            }
        }
    }
}

extension EntrySheet {
    var saveButtons: some View {
        HStack(spacing: 8) {
            PrimaryButton(
                model.saveTitle,
                subject: model.saveSubject,
                detail: saveDetail
            ) {
                Task {
                    await save()
                }
            }

            if !model.isEditing {
                CardButton(
                    "続けて記録",
                    style: .outlined(Palette.accent),
                    height: 56
                ) {
                    Task {
                        await saveAndContinue()
                    }
                }
                .frame(width: Self.continueWidth)
                .opacity(continueOpacity)
            }
        }
        .disabled(!model.canSave)
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

    static func categoryFill(_ isSelected: Bool) -> Color {
        isSelected ? Palette.accent.opacity(.subtle) : Color.clear
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

    var header: some View {
        HStack {
            RingButton(systemImage: "xmark") {
                close()
            }

            Spacer()

            CapsulePicker(selection: typeBinding, options: Self.typeOptions)

            Spacer()

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
    }

    var dial: some View {
        Button {
            tapDial()
        } label: {
            EntryDialFace(model: model)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private extension EntrySheet {
    static let fade: CGFloat = 20
    static let continueWidth: CGFloat = 104

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("振替", value: .transfer)
    ]

    var bannerBottom: CGFloat {
        isEnteringAmount ? drawerHeight + 12 : 12
    }

    var saveDetail: String? {
        model.saveDetail(today: today)
    }

    var continueOpacity: Double {
        model.canSave ? 1 : 0.4
    }

    var typeBinding: Binding<Entry.Kind> {
        Binding(
            get: {
                model.type
            },
            set: { type in
                var transaction = Transaction()

                transaction.disablesAnimations = true

                withTransaction(transaction) {
                    model.select(type)
                    showSelectedCategory()
                }
            }
        )
    }

    func close() {
        if model.isChanged {
            isConfirmingDiscard = true
        } else {
            dismiss()
        }
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
        }

        showSelectedCategory()
    }

    func save() async {
        guard let change = await model.save() else {
            return
        }

        onChange(change)
        dismiss()
    }

    func saveAndContinue() async {
        guard let change = await model.save() else {
            return
        }

        await model.startNext()
        notice.show(change)
        setEnteringAmount(true)
    }

    func delete() async {
        guard let change = await model.delete() else {
            return
        }

        onChange(change)
        dismiss()
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
