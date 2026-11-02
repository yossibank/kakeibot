import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    enum ReceiptStep: Hashable {
        case guide
        case camera
        case reading
    }

    static let receiptFeature = "4 回目からのレシートの読み取り"

    var showsReceiptButton: Bool {
        model.showsReceipt && EntryReceiptCamera.isSupported
    }

    var isScanningReceipt: Binding<Bool> {
        Binding(
            get: {
                receiptStep == .camera
            },
            set: { isScanning in
                if !isScanning, receiptStep == .camera {
                    receiptStep = nil
                }
            }
        )
    }

    var receiptButton: some View {
        ChipButton("レシート", systemImage: "doc.text.viewfinder") {
            startReceipt()
        }
    }

    @ViewBuilder
    var receiptLayer: some View {
        switch receiptStep {
        case .guide:
            EntryItemHelp(
                title: "レシートの撮り方",
                steps: EntryItemHelp.receiptSteps,
                buttonTitle: "撮る",
                onConfirm: {
                    receiptStep = .camera
                },
                onClose: {
                    withAnimation(.snappy) {
                        receiptStep = nil
                    }
                }
            )
        case .reading:
            readingCard
        case .camera, nil:
            EmptyView()
        }
    }

    var receiptCamera: some View {
        EntryReceiptCamera { pages in
            receiptStep = .reading

            Task {
                await readReceipt(pages)
            }
        } onCancel: {
            receiptStep = nil
        }
        .ignoresSafeArea()
    }

    func startReceipt() {
        guard model.canReadReceipt(isPro: isPro) else {
            receiptOffer = Self.receiptFeature
            return
        }

        receiptOffer = nil

        if model.showsReceiptGuide {
            withAnimation(.snappy) {
                receiptStep = .guide
            }
        } else {
            receiptStep = .camera
        }
    }
}

private extension EntrySheet {
    static let readingMessage = "レシートを読んでいます"
    static let unreadMessage = "レシートを読めませんでした。明るい所で撮り直してください"

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

    func readReceipt(_ pages: [CGImage]) async {
        let reading = await EntryReceiptReader.read(pages)

        withAnimation(.snappy) {
            receiptStep = nil
        }

        guard !reading.isEmpty else {
            model.errorNotice.show(Self.unreadMessage)
            return
        }

        await model.apply(reading)

        if model.amount > 0 {
            setEnteringAmount(false)
        }
    }
}
