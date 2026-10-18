import SwiftUI

public struct NoticeBanner: View {
    let message: String
    let systemImage: String
    let tone: Tone
    let actionTitle: String?
    let action: (() -> Void)?

    public init(
        _ message: String,
        systemImage: String,
        tone: Tone = .info,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.message = message
        self.systemImage = systemImage
        self.tone = tone
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.sans(.caption, weight: .semibold))
                .foregroundStyle(tone.color)
                .frame(width: 30, height: 30)
                .background(tone.color.opacity(0.12), in: Circle())
                .overlay {
                    Circle()
                        .strokeBorder(tone.color.opacity(0.45), lineWidth: 0.6)
                }

            Text(message)
                .font(.footnote)
                .foregroundStyle(Palette.ink)
                .lineLimit(2)

            Spacer(minLength: 8)

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Palette.gold)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    Palette.gold.opacity(.medium),
                                    lineWidth: 0.8
                                )
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 11)
        .padding(.trailing, 9)
        .frame(minHeight: 54)
        .background {
            ZStack {
                Capsule()
                    .fill(Palette.drawer)

                Capsule()
                    .fill(Self.sheen)
            }
        }
        .overlay {
            Capsule()
                .strokeBorder(rim, lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
    }
}

public extension NoticeBanner {
    enum Tone: Sendable {
        case info
        case error
    }
}

extension NoticeBanner.Tone {
    var color: Color {
        switch self {
        case .info: Palette.gold
        case .error: Palette.rose
        }
    }
}

private extension NoticeBanner {
    static var sheen: LinearGradient {
        LinearGradient(
            colors: [.white.opacity(0.06), .white.opacity(0)],
            startPoint: .top,
            endPoint: .center
        )
    }

    var rim: LinearGradient {
        LinearGradient(
            colors: [tone.color.opacity(0.8), tone.color.opacity(0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        NoticeBanner(
            "ランチ ¥980 を記録しました",
            systemImage: "checkmark",
            actionTitle: "取り消す"
        ) {}

        NoticeBanner(
            "名前を入れてください",
            systemImage: "exclamationmark",
            tone: .error
        )
    }
    .padding()
    .background(Palette.night)
}
