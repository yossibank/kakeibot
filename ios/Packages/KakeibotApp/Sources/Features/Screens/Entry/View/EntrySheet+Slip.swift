import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var showsRecent: Bool {
        isBlankEntry && (deck == .category || deck == .transfer)
    }

    var summary: some View {
        EntrySlip(
            model: model,
            deck: deck,
            today: today,
            isMemoActive: isEditingMemo,
            listening: voice.step == .listening ? voice : nil,
            preview: voice.preview,
            growth: slipGrowth,
            onSelect: { next in
                show(next)
            },
            onMemo: {
                editMemo(true)
            },
            onOpenItems: {
                open(.items)
            },
            onReceipt: quickReceipt,
            onVoice: quickVoice
        )
    }
}

private extension EntrySheet {
    var isBlankEntry: Bool {
        !model.isEditing && model.amount <= 0
    }

    var quickReceipt: (() -> Void)? {
        guard
            showsReceiptButton,
            !voice.isActive
        else {
            return nil
        }

        return startReceipt
    }

    var quickVoice: (() -> Void)? {
        guard
            showsVoiceButton,
            !voice.isActive
        else {
            return nil
        }

        return startVoice
    }

    func startReceipt() {
        withAnimation(.snappy) {
            receipt.start(for: model, isPro: isPro)
        }
    }
}
