import Core
import SwiftUI

public struct ConfirmCard: View {
    private let systemImage: String
    private let title: String
    private let message: String?
    private let keepTitle: String
    private let confirmTitle: String
    private let alternateTitle: String?
    private let role: Role
    private let onConfirm: () -> Void
    private let onAlternate: () -> Void
    private let onKeep: () -> Void

    public init(
        systemImage: String,
        title: String,
        message: String? = nil,
        keepTitle: String,
        confirmTitle: String,
        alternateTitle: String? = nil,
        role: Role = .destructive,
        onConfirm: @escaping () -> Void,
        onAlternate: @escaping () -> Void = {},
        onKeep: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.keepTitle = keepTitle
        self.confirmTitle = confirmTitle
        self.alternateTitle = alternateTitle
        self.role = role
        self.onConfirm = onConfirm
        self.onAlternate = onAlternate
        self.onKeep = onKeep
    }

    public var body: some View {
        ModalCard(onDismiss: onKeep) {
            card
        }
    }
}

public extension ConfirmCard {
    enum Role: Sendable {
        case destructive
        case suggestion
    }
}

private extension ConfirmCard {
    var card: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .sansFont(.headline, weight: .ultraLight)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(Palette.accent.opacity(.medium), lineWidth: 0.8)
                    }

                Text(title)
                    .displayFont(.headline, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let message {
                    Text(message)
                        .textFont(.caption)
                        .foregroundStyle(Palette.subtext)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 12) {
                if let alternateTitle {
                    CardButton(alternateTitle, style: .filled, action: onAlternate)

                    CardButton(confirmTitle, style: .outlined(Palette.rose), action: onConfirm)

                    CardButton(keepTitle, style: .outlined(Palette.subtext), action: onKeep)
                } else {
                    twoChoices
                }
            }
        }
    }

    @ViewBuilder
    var twoChoices: some View {
        switch role {
        case .destructive:
            CardButton(keepTitle, style: .filled, action: onKeep)

            CardButton(confirmTitle, style: .outlined(Palette.rose), action: onConfirm)
        case .suggestion:
            CardButton(confirmTitle, style: .filled, action: onConfirm)

            CardButton(keepTitle, style: .outlined(Palette.subtext), action: onKeep)
        }
    }
}

public extension View {
    func confirmation(
        isPresented: Binding<Bool>,
        systemImage: String,
        title: String,
        message: String? = nil,
        keepTitle: String,
        confirmTitle: String,
        alternateTitle: String? = nil,
        role: ConfirmCard.Role = .destructive,
        onKeep: @escaping () -> Void = {},
        onAlternate: @escaping () -> Void = {},
        onConfirm: @escaping () -> Void
    ) -> some View {
        let feedback: SensoryFeedback = role == .destructive ? .warning : .selection

        return overlay {
            if isPresented.wrappedValue {
                ConfirmCard(
                    systemImage: systemImage,
                    title: title,
                    message: message,
                    keepTitle: keepTitle,
                    confirmTitle: confirmTitle,
                    alternateTitle: alternateTitle,
                    role: role,
                    onConfirm: {
                        isPresented.wrappedValue = false
                        onConfirm()
                    },
                    onAlternate: {
                        isPresented.wrappedValue = false
                        onAlternate()
                    },
                    onKeep: {
                        isPresented.wrappedValue = false
                        onKeep()
                    }
                )
            }
        }
        .animation(.snappy(duration: 0.25), value: isPresented.wrappedValue)
        .haptic(feedback, trigger: isPresented.wrappedValue) { _, new in
            new
        }
    }
}

#Preview {
    ConfirmCard(
        systemImage: "eye.slash",
        title: "この口座を非表示にしますか",
        message: "残高 ¥182,000 は、資産タブの合計から外れます",
        keepTitle: "やめる",
        confirmTitle: "非表示にする",
        onConfirm: {},
        onKeep: {}
    )
    .background(Palette.background)
}
