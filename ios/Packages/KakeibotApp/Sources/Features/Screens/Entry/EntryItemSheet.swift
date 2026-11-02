import Core
import DesignSystem
import Store
import SwiftUI

struct EntryItemSheet: View {
    @Bindable var model: EntryModel

    @State var name = ""
    @State var unit = AmountCalculator()
    @State var quantity = AmountCalculator(amount: 1)
    @State var target: Target = .unit
    @State var editingIndex: Int?
    @State var editingItem: EntryItem.Draft?
    @State var taxRate: EntryItem.TaxRate?
    @State var isDiscount = false
    @State var isSlipOpen = false
    @State var scrollRequest: ScrollRequest?
    @State var removed: EntryModel.RemovedItem?
    @State var openIndex: Int?

    @FocusState var focus: Field?

    @Environment(\.themeStyle.corner) var corner

    @State private var isShowingHelp = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { _ in
            content
        }
        .ignoresSafeArea(.keyboard)
        .overlay {
            if isShowingHelp {
                EntryGuideCard(guide: .items) {
                    withAnimation(.snappy) {
                        isShowingHelp = false
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

private extension EntryItemSheet {
    var content: some View {
        VStack(spacing: 0) {
            HStack {
                RingButton(systemImage: "questionmark") {
                    withAnimation(.snappy) {
                        isShowingHelp = true
                    }
                }

                Spacer()

                RingButton(systemImage: "checkmark", style: .prominent) {
                    dismiss()
                }
            }
            .overlay {
                SheetTitle("品目")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            ScrollViewReader { proxy in
                ScrollView {
                    receipt
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: scrollRequest) { _, request in
                    guard let request else {
                        return
                    }

                    withAnimation(.snappy) {
                        proxy.scrollTo(request.index, anchor: .top)
                    }
                }
            }

            if isSlipOpen {
                slip
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                addBar
            }
        }
        .settingsHideNotice(
            $removed,
            message: "品目を消しました",
            systemImage: "trash",
            bottom: Self.noticeBottom
        ) { removed in
            restore(removed)
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
                .onTapGesture {
                    focus = nil
                }
        }
    }
}

extension EntryItemSheet {
    init(
        model: EntryModel,
        isSlipOpen: Bool = false
    ) {
        _isSlipOpen = State(initialValue: isSlipOpen)

        self.model = model
    }
}

private extension EntryItemSheet {
    var receipt: some View {
        VStack(spacing: 12) {
            VStack(spacing: 2) {
                Text(dateText)
                    .textFont(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(Palette.subtext)

                TextField(
                    "店名",
                    text: $model.store,
                    prompt: Text("店名を入れる").foregroundStyle(Palette.hint)
                )
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(Palette.text)
                .multilineTextAlignment(.center)
                .tint(Palette.accent)
                .submitLabel(.done)
                .focused($focus, equals: .store)
            }

            EntryReceiptRule(style: .dashed)

            if model.items.isEmpty {
                VStack(spacing: 4) {
                    Text("品目はまだありません")
                        .textFont(.subheadline)
                        .foregroundStyle(Palette.subtext)

                    Text("下の「品目を追加」から追加できます。")
                        .textFont(.caption)
                        .foregroundStyle(Palette.hint)
                }
                .frame(maxWidth: .infinity, minHeight: 72)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.items.enumerated()), id: \.offset) { index, item in
                        itemRow(item, at: index)
                            .id(index)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }

            EntryReceiptRule(style: .dashed)

            summaryLine("小計", amount: model.itemTotals.subtotal)

            if !model.itemTotals.taxes.isEmpty {
                taxModeLine
            }

            ForEach(model.itemTotals.taxes, id: \.rate) { tax in
                taxLine(tax)
            }

            if model.hasItemAdjustment {
                adjustmentLine

                if !model.suspectItemIndices.isEmpty {
                    suspectHint
                }
            }

            EntryReceiptRule(style: .double)

            HStack(alignment: .firstTextBaseline) {
                Text("合計")
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Spacer()

                Text(AmountText.text(model.amount))
                    .displayFont(.title, weight: .bold)
                    .monospacedDigit()
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }

            if !model.items.isEmpty {
                HStack {
                    Text("お買上点数")
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)

                    Spacer()

                    Text("\(model.itemCount)点")
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background {
            receiptShape
                .fill(Palette.card)
                .shadow(color: Palette.shadow.opacity(0.6), radius: 12, y: 4)
        }
    }

    var adjustmentLine: some View {
        HStack(spacing: 8) {
            Text("差額")
                .textFont(.subheadline)
                .foregroundStyle(Palette.amber)

            Button {
                model.adjustToItems()
            } label: {
                Text("調整")
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .overlay {
                        Capsule()
                            .stroke(Palette.accent.opacity(.medium), lineWidth: 1)
                    }
                    .frame(minHeight: 32)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(!model.canAdjustToItems)

            Spacer()

            Text(AmountText.text(model.itemAdjustment))
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.amber)
        }
    }

    var taxModeLine: some View {
        HStack(spacing: 6) {
            Text("税の計算")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Spacer()

            CapsulePicker(
                selection: Binding(
                    get: { model.taxIncluded },
                    set: { model.setTaxIncluded($0) }
                ),
                options: Self.taxModeOptions,
                size: .small
            )
            .frame(width: Self.taxModeWidth)
        }
    }

    var suspectHint: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.magnifyingglass")

            Text("色の付いた行が、読み違えているかもしれません")
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .textFont(.caption)
        .foregroundStyle(Palette.amber)
    }

    func itemRow(
        _ item: EntryItem.Draft,
        at index: Int
    ) -> some View {
        let isEditing = isSlipOpen && editingIndex == index
        let isSuspect = model.suspectItemIndices.contains(index)

        return SwipeRow(
            id: index,
            openId: $openIndex,
            actionInset: 2
        ) {
            edit(index)
        } onAction: {
            remove(index)
        } content: {
            HStack(spacing: 8) {
                IconImage(categoryIcon, size: 13)
                    .foregroundStyle(Palette.accent)
                    .frame(width: Self.iconWidth)

                Text(item.trimmedName)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if let quantity = EntryModel.quantityText(for: item) {
                    Text(quantity)
                        .textFont(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                }

                Spacer(minLength: 8)

                Text(AmountText.text(item.amount))
                    .textFont(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(isSuspect ? Palette.amber : Palette.text)

                if showsRates {
                    Text(item.taxRate.map { "\($0.rawValue)%" } ?? "")
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.accent)
                        .frame(width: Self.rateWidth, alignment: .trailing)
                }
            }
            .padding(.vertical, 7)
            .padding(.horizontal, 4)
            .background {
                ZStack {
                    Rectangle()
                        .fill(Palette.card)

                    if isEditing {
                        Rectangle()
                            .fill(Palette.accent.opacity(.subtle))
                    } else if isSuspect {
                        Rectangle()
                            .fill(Palette.amber.opacity(.subtle))
                            .overlay(alignment: .leading) {
                                Rectangle()
                                    .fill(Palette.amber)
                                    .frame(width: 2)
                            }
                    }
                }
            }
        }
        .padding(.horizontal, -4)
    }

    func summaryLine(
        _ title: String,
        amount: Int
    ) -> some View {
        HStack {
            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(Palette.subtext)

            Spacer()

            Text(AmountText.text(amount))
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
    }

    func taxLine(_ tax: EntryItemTotal.Tax) -> some View {
        HStack {
            Text("\(tax.rate.rawValue)%対象")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(tax.base))
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Spacer()

            Text(model.taxIncluded ? "うち消費税" : "消費税")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Text(AmountText.text(tax.amount))
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.text)
        }
    }
}

private extension EntryItemSheet {
    static let noticeBottom: CGFloat = 76
    static let iconWidth: CGFloat = 18
    static let rateWidth: CGFloat = 28
    static let taxModeWidth: CGFloat = 136

    static let taxModeOptions: [CapsulePicker<Bool>.Option] = [
        .init("外税", value: false),
        .init("内税", value: true)
    ]

    var showsRates: Bool {
        Set(model.items.map(\.taxRate)).count > 1
    }

    var receiptShape: EntryReceiptShape {
        EntryReceiptShape(tooth: 12, hasTopEdge: true)
    }

    var dateText: String {
        let date = model.date
        return "\(date.year)/\(date.month)/\(date.day)（\(date.weekday.shortName)）"
    }

    var categoryIcon: Icon? {
        model.selectedCategory.flatMap { model.icon(for: $0) }
    }

    func restore(_ removed: EntryModel.RemovedItem) {
        if let editingIndex,
           removed.index <= editingIndex {
            self.editingIndex = editingIndex + 1
        }

        model.restoreItem(removed)
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let today = LocalDate(Date(), in: .current)

        EntryItemSheet(model: EntryModel(database: database, date: today))
    }
}
