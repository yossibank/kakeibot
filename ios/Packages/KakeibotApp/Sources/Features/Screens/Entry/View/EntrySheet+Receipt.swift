import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var showsReceiptButton: Bool {
        model.showsReceipt && canScanReceipt
    }

    var isScanningReceipt: Binding<Bool> {
        Binding(
            get: {
                receipt.isScanning
            },
            set: { isScanning in
                if !isScanning, receipt.isScanning {
                    receipt.cancel()
                }
            }
        )
    }

    @ViewBuilder
    var receiptLayer: some View {
        switch receipt.step {
        case .guide:
            EntryGuideCard(
                onConfirm: {
                    receipt.confirmGuide()
                    saveReceiptGuideChoice()
                },
                hidesNext: $receipt.hidesGuide,
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

        guard case let .read(itemCount, _) = outcome else {
            return
        }

        guard itemCount > 0 else {
            return
        }

        try? await Task.sleep(for: Self.coverDismissDelay)

        open(.items)
    }
}
