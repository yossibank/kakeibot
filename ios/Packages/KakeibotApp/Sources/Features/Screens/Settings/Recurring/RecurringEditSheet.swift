import Core
import DesignSystem
import Store
import SwiftUI

public struct RecurringEditSheet: View {
    @State private var model: RecurringEditModel
    @State private var panel: Panel?
    @State private var isConfirmingDiscard = false
    @State private var isConfirmingDelete = false

    @FocusState private var isNameFocused: Bool

    @Environment(\.dismiss) private var dismiss

    private let onDelete: (Deletion) -> Void

    public init(
        model: RecurringEditModel,
        onDelete: @escaping (Deletion) -> Void = { _ in }
    ) {
        _model = State(initialValue: model)

        self.onDelete = onDelete
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            content

            if let panel {
                Palette.scrim
                    .opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        closePanel()
                    }
                    .transition(.opacity)
                    .zIndex(1)

                SettingsDrawer(title(for: panel)) {
                    closePanel()
                } content: {
                    drawerBody(panel)
                }
                .transition(.settingsDrawer)
                .zIndex(1)
            }
        }
        .overlay(alignment: .top) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 20)
        }
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
                .onTapGesture {
                    isNameFocused = false
                }
        }
        .confirmsDiscard(
            when: model.isChanged,
            isPresented: $isConfirmingDiscard
        ) {
            dismiss()
        }
        .confirmation(
            isPresented: $isConfirmingDelete,
            systemImage: "trash",
            title: "この固定費を削除しますか",
            message: "これまでに作った記録は残ります",
            keepTitle: "やめる",
            confirmTitle: "削除する"
        ) {
            Task {
                await delete()
            }
        }
        .task {
            await model.load()
        }
    }
}

private extension RecurringEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            Color.clear
                .frame(height: 44)

            ScrollView {
                VStack(spacing: 20) {
                    if !model.isEditing {
                        CapsulePicker(
                            selection: typeBinding,
                            options: Self.typeOptions
                        )
                    }

                    hero

                    SettingsRowList(items: rowItems) { panel in
                        open(panel)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)

            PrimaryButton(model.saveTitle) {
                Task {
                    await save()
                }
            }
            .disabled(!model.canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    var header: some View {
        SettingsEditHeader(
            title: headerTitle,
            isEditing: model.isEditing,
            isHidden: model.isHidden
        ) {
            close()
        } onHide: {
            Task {
                await setHidden(!model.isHidden)
            }
        } onDelete: {
            isConfirmingDelete = true
        }
    }

    var hero: some View {
        VStack(spacing: 16) {
            Button {
                open(amountPanel)
            } label: {
                Text(amountText)
                    .displayFont(.largeTitle, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)

            TextField(
                "名前",
                text: $model.memo,
                prompt: Text(namePrompt)
                    .foregroundStyle(Palette.hint)
            )
            .multilineTextAlignment(.center)
            .displayFont(.body)
            .foregroundStyle(Palette.accentStrong)
            .tint(Palette.accent)
            .submitLabel(.done)
            .focused($isNameFocused)
            .padding(.bottom, 8)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Palette.accent.opacity(.medium))
                    .frame(height: 1)
            }
            .padding(.horizontal, 40)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .card()
    }

    var scheduleChooser: some View {
        VStack(spacing: 16) {
            CapsulePicker(
                selection: $model.frequency,
                options: Self.frequencyOptions
            )

            if model.frequency == .yearly {
                LazyVGrid(columns: Self.monthColumns, spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        SettingsChoice(
                            "\(month) 月",
                            isSelected: model.month == month
                        ) {
                            model.month = month
                        }
                    }
                }
                .transition(Self.monthTransition)
            }

            MonthStartDayGrid(
                selection: MonthStartDay(model.day) ?? .first
            ) { day in
                model.day = day.day
            }
        }
        .padding(.bottom, 8)
    }

    var endChooser: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                SettingsChoice("終わりなし", isSelected: model.endDate == nil) {
                    model.endDate = nil

                    closePanel()
                }

                SettingsChoice("今日で終える", isSelected: isEndingToday) {
                    model.endDate = model.today

                    closePanel()
                }
            }

            MonthCalendar(selection: endBinding, today: model.today)
        }
    }

    var holidayChooser: some View {
        VStack(spacing: 12) {
            Text("土日・祝日・年末年始（12/31〜1/3）に当たったときに、日をずらします")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            HStack(spacing: 8) {
                ForEach(
                    Recurring.HolidayShift.allCases,
                    id: \.self
                ) { shift in
                    SettingsChoice(
                        RecurringText.holidayShift(shift),
                        isSelected: model.holidayShift == shift
                    ) {
                        model.choose(shift)
                        closePanel()
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    var closingChooser: some View {
        VStack(spacing: 12) {
            Text("締め日までのカードの利用分を、引き落とし日に振り替えます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)
                .multilineTextAlignment(.center)

            SettingsChoice(
                RecurringText.closingDay(nil),
                isSelected: model.closingDay == nil
            ) {
                model.closingDay = nil

                closePanel()
            }

            MonthStartDayGrid(
                selection: model.closingDay.flatMap(MonthStartDay.init)
            ) { day in
                model.closingDay = day.day

                closePanel()
            }
        }
        .padding(.bottom, 8)
    }

    var remindChooser: some View {
        LazyVGrid(columns: Self.remindColumns, spacing: 8) {
            ForEach(
                RecurringEditModel.remindChoices,
                id: \.self
            ) { days in
                SettingsChoice(
                    RecurringText.remind(days),
                    isSelected: model.remindDaysBefore == days
                ) {
                    model.remindDaysBefore = days

                    closePanel()
                }
            }
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            VStack(spacing: 12) {
                Keypad(activeTax: model.calculator.taxNote?.rate) { key in
                    model.press(key)
                }

                PrimaryButton("決める") {
                    closePanel()
                }
            }
        case .category:
            SettingsTileGrid(
                items: model.categories,
                columns: 5,
                spacing: 4
            ) { category in
                SettingsCategoryTile(
                    category: category,
                    icon: model.icon(for: category),
                    isSelected: model.categoryId == category.id
                ) {
                    model.select(category: category.id)
                    closePanel()
                }
            }
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
        case .destination:
            SettingsTileGrid(
                items: model.wallets,
                columns: 3,
                spacing: 8
            ) { wallet in
                SettingsWalletTile(
                    wallet: wallet,
                    icon: model.icon(for: wallet),
                    isSelected: model.toWalletId == wallet.id
                ) {
                    model.toWalletId = wallet.id

                    closePanel()
                }
            }
            .padding(.bottom, 8)
        case .schedule:
            scheduleChooser
        case .start:
            MonthCalendar(selection: $model.startDate, today: model.today)
        case .end:
            endChooser
        case .holiday:
            holidayChooser
        case .closing:
            closingChooser
        case .remind:
            remindChooser
        }
    }
}

private extension RecurringEditSheet {
    enum Panel: Hashable {
        case amount
        case category
        case wallet
        case destination
        case schedule
        case start
        case end
        case holiday
        case closing
        case remind
    }

    static let typeOptions: [CapsulePicker<Entry.Kind>.Option] = [
        .init("支出", value: .expense),
        .init("収入", value: .income),
        .init("振替", value: .transfer)
    ]

    static let frequencyOptions: [CapsulePicker<Recurring.Frequency>.Option] =
        [
            .init("毎月", value: .monthly),
            .init("毎年", value: .yearly)
        ]

    static let monthColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 4
    )

    static let remindColumns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    static var monthTransition: AnyTransition {
        .asymmetric(
            insertion: .opacity.animation(.snappy.delay(0.15)),
            removal: .identity
        )
    }

    var namePrompt: String {
        switch model.type {
        case .expense: "名前（家賃・サブスクなど）"
        case .income: "名前（給料・年金など）"
        case .transfer: "名前（カードの引き落とし・積立など）"
        }
    }

    var headerTitle: String {
        model.isEditing ? "固定費を編集" : "固定費を追加"
    }

    var amountColor: Color {
        let isSet = model.amount > 0 || model.isCardBill

        return isSet ? Palette.accentStrong : Palette.hint
    }

    var amountText: String {
        model.isCardBill ? "カードの利用分" : AmountText.text(model.amount)
    }

    var amountPanel: Panel {
        model.isCardBill ? .closing : .amount
    }

    var typeBinding: Binding<Entry.Kind> {
        Binding {
            model.type
        } set: { type in
            model.select(type)
        }
    }

    var isEndingToday: Bool {
        model.endDate == model.today
    }

    var endBinding: Binding<LocalDate> {
        Binding {
            model.endDate ?? model.startDate
        } set: { date in
            model.endDate = date
        }
    }

    var scheduleText: String {
        RecurringText.schedule(
            model.frequency,
            month: model.month,
            day: model.day
        )
    }

    var rowItems: [SettingsRowList<Panel>.Item] {
        moneyItems + scheduleItems
    }

    var moneyItems: [SettingsRowList<Panel>.Item] {
        let wallet = SettingsRowList<Panel>.Item(
            panel: .wallet,
            systemImage: "wallet.bifold",
            title: model.walletTitle,
            value: model.selectedWallet?.name ?? "選ぶ",
            isEmpty: model.selectedWallet == nil
        )

        guard model.type == .transfer else {
            let category = SettingsRowList<Panel>.Item(
                panel: .category,
                systemImage: "square.grid.2x2",
                title: "カテゴリ",
                value: model.selectedCategory?.name ?? "選ぶ",
                isEmpty: model.selectedCategory == nil
            )

            return [category, wallet]
        }

        let destination = SettingsRowList<Panel>.Item(
            panel: .destination,
            systemImage: "arrow.right.circle",
            title: RecurringEditModel.destinationTitle,
            value: model.selectedDestination?.name ?? "選ぶ",
            isEmpty: model.selectedDestination == nil
        )

        guard model.canUseClosingDay else {
            return [wallet, destination]
        }

        let closing = SettingsRowList<Panel>.Item(
            panel: .closing,
            systemImage: "creditcard",
            title: "金額の決め方",
            value: RecurringText.closingDay(model.closingDay),
            isEmpty: model.closingDay == nil
        )

        return [wallet, destination, closing]
    }

    var scheduleItems: [SettingsRowList<Panel>.Item] {
        [
            .init(
                panel: .schedule,
                systemImage: "repeat",
                title: "繰り返し",
                value: scheduleText,
                isEmpty: false
            ),
            .init(
                panel: .start,
                systemImage: "calendar",
                title: "始まり",
                value: RecurringText.date(model.startDate),
                isEmpty: false
            ),
            .init(
                panel: .end,
                systemImage: "calendar.badge.checkmark",
                title: "終わり",
                value: model.endDate.map(RecurringText.date) ?? "なし",
                isEmpty: model.endDate == nil
            ),
            .init(
                panel: .holiday,
                systemImage: "calendar.badge.exclamationmark",
                title: "休日なら",
                value: RecurringText.holidayShift(model.holidayShift),
                isEmpty: model.holidayShift == .none
            ),
            .init(
                panel: .remind,
                systemImage: "bell",
                title: "前に知らせる",
                value: RecurringText.remind(model.remindDaysBefore),
                isEmpty: model.remindDaysBefore == nil
            )
        ]
    }

    func title(for panel: Panel) -> String {
        switch panel {
        case .amount: "金額"
        case .category: "カテゴリ"
        case .wallet: model.walletTitle
        case .destination: RecurringEditModel.destinationTitle
        case .schedule: "繰り返し"
        case .start: "始まり"
        case .end: "終わり"
        case .holiday: "休日なら"
        case .closing: "金額の決め方"
        case .remind: "前に知らせる"
        }
    }

    func open(_ panel: Panel) {
        isNameFocused = false

        withAnimation(.snappy) {
            self.panel = panel
        }
    }

    func closePanel() {
        withAnimation(.snappy) {
            panel = nil
        }
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

        if await model.save() {
            dismiss()
        }
    }

    func delete() async {
        if let deletion = await model.delete() {
            onDelete(deletion)
            dismiss()
        }
    }

    func setHidden(_ isHidden: Bool) async {
        if await model.setHidden(isHidden) {
            dismiss()
        }
    }
}
