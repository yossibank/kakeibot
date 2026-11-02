import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var showsReceiptButton: Bool {
        model.showsReceipt && EntryReceiptCamera.isSupported
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
        ChipButton("レシート", systemImage: "doc.text.viewfinder") {
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
            readingCard
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
    static let readingMessage = "レシートを読んでいます"

    var readingCard: some View {
        ZStack {
            Palette.scrim
                .opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                    .tint(Palette.accent)

                Text(Self.readingMessage)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)
            }
            .padding(24)
            .background(Palette.card, in: .rect(cornerRadius: corner.radius(20)))
        }
        .transition(.opacity)
    }

    func scanReceipt(_ pages: [CGImage]) async {
        let readAmount = await receipt.scan(pages, into: model)

        if readAmount {
            setEnteringAmount(false)
        }
    }
}
