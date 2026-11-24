import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension EntrySheet {
    var showsReceiptButton: Bool {
        model.output.showsReceipt && canScanReceipt
    }

    var isScanningReceipt: Binding<Bool> {
        Binding(
            get: {
                receipt.output.isScanning
            },
            set: { isScanning in
                if !isScanning, receipt.output.isScanning {
                    receipt.cancel()
                }
            }
        )
    }

    @ViewBuilder
    var receiptLayer: some View {
        switch receipt.state.step {
        case .guide:
            EntryGuideCard(
                onConfirm: {
                    receipt.confirmGuide()
                    saveReceiptGuideChoice()
                },
                hidesNext: Bindable(receipt.state).hidesGuide,
                guide: .receipt
            ) {
                withAnimation(.snappy) {
                    receipt.cancel()
                }

                saveReceiptGuideChoice()
            }

        case .reading:
            EntryReceiptReadingCard()

        case .camera, nil:
            EmptyView()
        }
    }

    var receiptCamera: some View {
        EntryReceiptCamera { pages in
            Task {
                await scanReceipt(pages)
            }
        } onCancel: {
            receipt.cancel()
        }
        .ignoresSafeArea()
    }
}

private extension EntrySheet {
    static let coverDismissDelay: Duration = .milliseconds(400)
}

private extension EntrySheet {
    func saveReceiptGuideChoice() {
        Task {
            await receipt.saveGuideChoice(for: model)
        }
    }

    func scanReceipt(_ pages: [CGImage]) async {
        let outcome = await receipt.scan(pages, into: model)

        guard case let .read(itemCount, _) = outcome, itemCount > 0 else {
            return
        }

        try? await Task.sleep(for: Self.coverDismissDelay)

        open(.items)
    }
}
