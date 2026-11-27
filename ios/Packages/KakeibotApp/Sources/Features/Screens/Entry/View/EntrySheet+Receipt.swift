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
        switch receipt.state.presented.step {
        case .guide:
            EntryGuideCard(
                onConfirm: {
                    receipt.confirmGuide()
                    saveReceiptGuideChoice()
                },
                hidesNext: Bindable(receipt.state).fields.hidesGuide,
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
            receipt.perform {
                await $0.scan(pages, into: model)
            }
        } onCancel: {
            receipt.cancel()
        }
        .ignoresSafeArea()
    }
}

private extension EntrySheet {
    func saveReceiptGuideChoice() {
        receipt.perform {
            await $0.saveGuideChoice(for: model)
        }
    }
}
