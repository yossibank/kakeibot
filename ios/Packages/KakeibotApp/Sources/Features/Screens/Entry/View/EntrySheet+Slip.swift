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
            isListening: voice.step == .listening,
            preview: voice.preview,
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

    var board: some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: corner.radius(28),
            topTrailingRadius: corner.radius(28)
        )

        return shape
            .fill(Palette.card)
            .overlay {
                shape
                    .fill(Self.boardLight)
            }
            .overlay {
                shape
                    .stroke(Palette.accent.opacity(.soft), lineWidth: 1)
            }
            .overlay(alignment: .top) {
                Self.boardEdge
                    .frame(height: 1)
                    .padding(.horizontal, 24)
            }
            .shadow(color: Palette.shadow.opacity(0.4), radius: 16, y: 6)
            .ignoresSafeArea(edges: .bottom)
    }
}

private extension EntrySheet {
    static var boardLight: RadialGradient {
        RadialGradient(
            colors: [Palette.accent.opacity(.subtle), .clear],
            center: .top,
            startRadius: 0,
            endRadius: 280
        )
    }

    static var boardEdge: LinearGradient {
        LinearGradient(
            colors: [.clear, Palette.accent, .clear],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

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
