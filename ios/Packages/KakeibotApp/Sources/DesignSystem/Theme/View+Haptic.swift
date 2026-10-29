import SwiftUI

public extension View {
    func haptic(
        _ feedback: SensoryFeedback,
        trigger: some Equatable
    ) -> some View {
        haptic(feedback, trigger: trigger) { _, _ in
            true
        }
    }

    func haptic<Trigger: Equatable>(
        _ feedback: SensoryFeedback,
        trigger: Trigger,
        condition: @escaping (Trigger, Trigger) -> Bool
    ) -> some View {
        modifier(
            Haptic(
                feedback: feedback,
                trigger: trigger,
                condition: condition
            )
        )
    }
}

private struct Haptic<Trigger: Equatable>: ViewModifier {
    @Environment(\.themeStyle.haptics) private var isOn

    let feedback: SensoryFeedback
    let trigger: Trigger
    let condition: (Trigger, Trigger) -> Bool

    func body(content: Content) -> some View {
        content
            .sensoryFeedback(feedback, trigger: trigger) { old, new in
                isOn && condition(old, new)
            }
    }
}
