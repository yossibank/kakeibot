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

    var receiptButton: some View {
        EntryReceiptButton(freeLeft: isPro ? nil : model.freeReceiptsLeft) {
            withAnimation(.snappy) {
                receipt.start(for: model, isPro: isPro)
            }
        }
    }

    @ViewBuilder
    var receiptLayer: some View {
        switch receipt.step {
        case .guide:
            EntryGuideCard(
                onConfirm: {
                    receipt.confirmGuide()
                },
                guide: .receipt
            ) {
                withAnimation(.snappy) {
                    receipt.cancel()
                }
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
    func scanReceipt(_ pages: [CGImage]) async {
        let outcome = await receipt.scan(pages, into: model)

        guard case let .read(itemCount, hasAmount) = outcome else {
            return
        }

        if hasAmount {
            setEnteringAmount(false)
        }

        guard itemCount > 0 else {
            return
        }

        try? await Task.sleep(for: Self.coverDismissDelay)

        open(.items)
    }
}
