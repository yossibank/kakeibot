import SwiftUI
import UIKit

public extension View {
    func confirmsDiscard(
        when isChanged: Bool,
        isPresented: Binding<Bool>,
        onDiscard: @escaping () -> Void
    ) -> some View {
        interactiveDismissDisabled(isChanged)
            .background {
                DismissAttemptReader {
                    isPresented.wrappedValue = true
                }
            }
            .overlay {
                if isPresented.wrappedValue {
                    DiscardCard(onDiscard: onDiscard) {
                        isPresented.wrappedValue = false
                    }
                }
            }
            .animation(.snappy(duration: 0.25), value: isPresented.wrappedValue)
            .sensoryFeedback(
                .warning,
                trigger: isPresented.wrappedValue
            ) { _, new in
                new
            }
    }
}

private struct DiscardCard: View {
    @State private var isShown = false

    let onDiscard: () -> Void
    let onKeep: () -> Void

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onKeep)

            card
                .scaleEffect(isShown ? 1 : 0.94)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.snappy(duration: 0.25)) {
                isShown = true
            }
        }
    }
}

private extension DiscardCard {
    var card: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: "pencil.slash")
                    .font(.system(size: 22, weight: .ultraLight))
                    .foregroundStyle(Palette.gold)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(Palette.gold.opacity(0.5), lineWidth: 0.8)
                    }

                Text("入力を捨てますか")
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundStyle(Palette.champagne)

                Text("閉じると、いま入れた内容は残らない")
                    .font(.caption)
                    .foregroundStyle(Palette.mist)
            }

            VStack(spacing: 10) {
                Button(action: onKeep) {
                    Text("入力を続ける")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.nightBottom)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Self.keepFill, in: Capsule())
                        .contentShape(Capsule())
                }

                Button(action: onDiscard) {
                    Text("捨てて閉じる")
                        .font(.subheadline)
                        .foregroundStyle(Palette.rose)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .overlay {
                            Capsule()
                                .stroke(
                                    Palette.rose.opacity(0.45),
                                    lineWidth: 1
                                )
                        }
                        .contentShape(Capsule())
                }
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(Palette.drawer, in: .rect(cornerRadius: 26))
        .overlay {
            RoundedRectangle(cornerRadius: 26)
                .stroke(Palette.gold.opacity(0.45), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.5), radius: 30, y: 14)
    }

    static var keepFill: LinearGradient {
        LinearGradient(
            colors: [Palette.champagne, Palette.gold],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private struct DismissAttemptReader: UIViewControllerRepresentable {
    let onAttempt: () -> Void

    func makeUIViewController(context: Context) -> DismissAttemptController {
        DismissAttemptController()
    }

    func updateUIViewController(
        _ controller: DismissAttemptController,
        context: Context
    ) {
        controller.onAttempt = onAttempt
    }
}

private final class DismissAttemptController: UIViewController {
    var onAttempt: () -> Void = {}

    private var original: (any UIAdaptivePresentationControllerDelegate)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard
            let presentation = presentationController,
            presentation.delegate !== self else {
            return
        }

        original = presentation.delegate
        presentation.delegate = self
    }
}

extension DismissAttemptController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(
        _ presentationController: UIPresentationController
    ) -> Bool {
        original?.presentationControllerShouldDismiss?(
            presentationController
        ) ?? true
    }

    func presentationControllerDidAttemptToDismiss(
        _ presentationController: UIPresentationController
    ) {
        onAttempt()

        original?.presentationControllerDidAttemptToDismiss?(
            presentationController
        )
    }

    func presentationControllerWillDismiss(
        _ presentationController: UIPresentationController
    ) {
        original?.presentationControllerWillDismiss?(presentationController)
    }

    func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController
    ) {
        original?.presentationControllerDidDismiss?(presentationController)
    }
}
