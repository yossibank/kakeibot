import Core
import DesignSystem
import FeatureModels
import SwiftUI

struct EntryItemSheet: View {
    @Environment(\.dismiss) private var dismiss

    let model: EntryModel

    @State var items: EntryItemModel
    @State var layout = Layout()

    @FocusState var focus: Field?

    @Environment(\.themeStyle.corner) var corner

    var body: some View {
        GeometryReader { _ in
            content
        }
        .ignoresSafeArea(.keyboard)
        .overlay {
            if items.state.presented.overlay.isShowing(.help) {
                EntryGuideCard(guide: .items) {
                    withAnimation(.snappy) {
                        items.state.presented.overlay.close(.help)
                    }
                }
            }
        }
        .presentationDragIndicator(.visible)
    }
}

extension EntryItemSheet {
    struct Layout {
        var scrollPosition = ScrollPosition()
        var scrollGeometry: ScrollGeometry?
        var slipHeight: CGFloat = 0
        var barHeight: CGFloat = 0
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

    var draft: EntryItemModel.Draft {
        items.state.fields.draft
    }

    var showsRates: Bool {
        Set(model.state.items.list.map(\.taxRate)).count > 1
    }

    var receiptShape: EntryReceiptShape {
        EntryReceiptShape(tooth: 12, hasTopEdge: true)
    }

    var dateText: String {
        let date = model.state.payment.date
        return "\(date.year)/\(PeriodText.weekdayDate(date))"
    }

    init(
        model: EntryModel,
        isSlipOpen: Bool = false
    ) {
        _items = State(initialValue: model.newItemModel(isSlipOpen: isSlipOpen))

        self.model = model
    }

    func restore(_ removed: EntryModel.RemovedItem) {
        items.restore(removed, in: model)
    }
}

private extension EntryItemSheet {
    var content: some View {
        VStack(spacing: 0) {
            header

            receiptScroll

            if items.state.presented.isSlipOpen {
                slip
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        layout.slipHeight = height
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                addBar
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.size.height
                    } action: { height in
                        layout.barHeight = height
                    }
            }
        }
        .undoNotice(
            items.state.notices.removed,
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

    var header: some View {
        HStack {
            RingButton(systemImage: "questionmark") {
                withAnimation(.snappy) {
                    items.state.presented.overlay.show(.help)
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
    }

    var receiptScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                receipt
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .scrollPosition($layout.scrollPosition)
            .onScrollGeometryChange(for: ScrollGeometry.self) { geometry in
                geometry
            } action: { _, geometry in
                layout.scrollGeometry = geometry
            }
            .onOutcome(items.state.outcome) { index in
                withAnimation(.snappy) {
                    proxy.scrollTo(index, anchor: .top)
                }
            }
        }
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        let today = LocalDate(Date(), in: .current)

        EntryItemSheet(model: EntryModel(parts: parts, date: today))
    }
}
