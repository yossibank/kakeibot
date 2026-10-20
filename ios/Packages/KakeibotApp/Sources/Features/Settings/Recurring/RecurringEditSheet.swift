import Core
import DesignSystem
import Store
import SwiftUI

public struct RecurringEditSheet: View {
    @State private var model: RecurringEditModel
    @State private var panel: Panel?
    @State private var isConfirmingDiscard = false

    @FocusState private var isNameFocused: Bool

    @Environment(\.dismiss) private var dismiss

    public init(model: RecurringEditModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
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

                SettingsDrawer(title(for: panel)) {
                    closePanel()
                } content: {
                    drawerBody(panel)
                }
                .transition(.settingsDrawer)
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
                VStack(spacing: 18) {
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

            Text(headerTitle)
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.accent)

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

    var hero: some View {
        VStack(spacing: 14) {
            Button {
                open(.amount)
            } label: {
                Text(AmountText.text(model.amount))
                    .font(.serif(.largeTitle, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(amountColor)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)

            TextField(
                "名前",
                text: $model.memo,
                prompt: Text("名前（家賃・給料など）")
                    .foregroundStyle(Palette.hint)
            )
            .multilineTextAlignment(.center)
            .font(.serif(.body))
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

    @ViewBuilder
    func drawerBody(_ panel: Panel) -> some View {
        switch panel {
        case .amount:
            VStack(spacing: 10) {
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
        case .remind:
            remindChooser
        }
    }

    var scheduleChooser: some View {
        VStack(spacing: 14) {
            CapsulePicker(
                selection: $model.frequency,
                options: Self.frequencyOptions
            )

            if model.frequency == .yearly {
                LazyVGrid(columns: Self.monthColumns, spacing: 6) {
                    ForEach(1...12, id: \.self) { month in
                        SettingsChoice(
                            "\(month) 月",
                            isSelected: model.month == month
                        ) {
                            model.month = month
                        }
                    }
                }
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

    var remindChooser: some View {
        LazyVGrid(columns: Self.remindColumns, spacing: 6) {
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
        repeating: GridItem(.flexible(), spacing: 6),
        count: 4
    )

    static let remindColumns = Array(
        repeating: GridItem(.flexible(), spacing: 6),
        count: 3
    )

    var headerTitle: String {
        model.isEditing ? "固定費を編集" : "固定費を追加"
    }

    var amountColor: Color {
        model.amount > 0 ? Palette.accentStrong : Palette.hint
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

        return [wallet, destination]
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
        if await model.delete() {
            dismiss()
        }
    }
}
