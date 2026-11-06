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
    @State var scrollPosition = ScrollPosition()
    @State var scrollGeometry: ScrollGeometry?
    @State var slipHeight: CGFloat = 0
    @State var barHeight: CGFloat = 0

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
                .scrollPosition($scrollPosition)
                .onScrollGeometryChange(for: ScrollGeometry.self) { geometry in
                    geometry
                } action: { _, geometry in
                    scrollGeometry = geometry
                }
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
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        slipHeight = height
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                addBar
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        barHeight = height
                    }
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

extension EntryItemSheet {
    static let noticeBottom: CGFloat = 76
    static let discountIndent: CGFloat = 12
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
        return "\(date.year)/\(date.monthDayText)（\(date.weekday.shortName)）"
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
