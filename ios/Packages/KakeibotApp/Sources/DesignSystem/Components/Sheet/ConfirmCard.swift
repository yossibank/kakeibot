import SwiftUI

public struct ConfirmCard: View {
    @Environment(\.themeStyle.corner) private var corner

    @State private var isShown = false

    private let systemImage: String
    private let title: String
    private let message: String
    private let keepTitle: String
    private let confirmTitle: String
    private let role: Role
    private let onConfirm: () -> Void
    private let onKeep: () -> Void

    public init(
        systemImage: String,
        title: String,
        message: String,
        keepTitle: String,
        confirmTitle: String,
        role: Role = .destructive,
        onConfirm: @escaping () -> Void,
        onKeep: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.keepTitle = keepTitle
        self.confirmTitle = confirmTitle
        self.role = role
        self.onConfirm = onConfirm
        self.onKeep = onKeep
    }

    public var body: some View {
        let scale: CGFloat = isShown ? 1 : 0.94

        return ZStack {
            Palette.scrim
                .opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onKeep)

            card
                .scaleEffect(scale)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.snappy(duration: 0.25)) {
                isShown = true
            }
        }
    }
}

public extension ConfirmCard {
    enum Role: Sendable {
        case destructive
        case suggestion
    }
}

public extension View {
    func confirmation(
        isPresented: Binding<Bool>,
        systemImage: String,
        title: String,
        message: String,
        keepTitle: String,
        confirmTitle: String,
        role: ConfirmCard.Role = .destructive,
        onConfirm: @escaping () -> Void
    ) -> some View {
        overlay {
            if isPresented.wrappedValue {
                ConfirmCard(
                    systemImage: systemImage,
                    title: title,
                    message: message,
                    keepTitle: keepTitle,
                    confirmTitle: confirmTitle,
                    role: role,
                    onConfirm: {
                        isPresented.wrappedValue = false
                        onConfirm()
                    },
                    onKeep: {
                        isPresented.wrappedValue = false
                    }
                )
            }
        }
        .animation(.snappy(duration: 0.25), value: isPresented.wrappedValue)
        .sensoryFeedback(
            role == .destructive ? .warning : .selection,
            trigger: isPresented.wrappedValue
        ) { _, new in
            new
        }
    }
}

private extension ConfirmCard {
    var card: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.sans(.headline, weight: .ultraLight))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Circle()
                            .stroke(
                                Palette.accent.opacity(.medium),
                                lineWidth: 0.8
                            )
                    }

                Text(title)
                    .displayFont(.headline, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)
                    .multilineTextAlignment(.center)

                Text(message)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                switch role {
                case .destructive:
                    filledButton(keepTitle, action: onKeep)
                    outlinedButton(
                        confirmTitle,
                        color: Palette.rose,
                        action: onConfirm
                    )
                case .suggestion:
                    filledButton(confirmTitle, action: onConfirm)
                    outlinedButton(
                        keepTitle,
                        color: Palette.subtext,
                        action: onKeep
                    )
                }
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(Palette.panel, in: .rect(cornerRadius: corner.radius(26)))
        .overlay {
            RoundedRectangle(cornerRadius: corner.radius(26))
                .stroke(Palette.accent.opacity(.medium), lineWidth: 0.8)
        }
        .shadow(color: Palette.shadow.opacity(0.5), radius: 30, y: 14)
    }

    func filledButton(
        _ title: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .textFont(.subheadline, weight: .bold)
                .foregroundStyle(Palette.backgroundBottom)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Self.filledFill, in: Capsule())
                .contentShape(Capsule())
        }
    }

    func outlinedButton(
        _ title: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .textFont(.subheadline)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 48)
                .overlay {
                    Capsule()
                        .stroke(color.opacity(.medium), lineWidth: 1)
                }
                .contentShape(Capsule())
        }
    }

    static var filledFill: LinearGradient {
        LinearGradient(
            colors: [Palette.accentStrong, Palette.accent],
            startPoint: .top,
            endPoint: .bottom
        )
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
