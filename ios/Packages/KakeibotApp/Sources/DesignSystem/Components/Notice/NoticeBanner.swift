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
            NoticeMark(systemImage: systemImage, tone: tone)

            Text(message)
                .textFont(.footnote)
                .foregroundStyle(Palette.text)
                .lineLimit(2)

            Spacer(minLength: 8)

            if let actionTitle,
               let action {
                Button(action: action) {
                    NoticeActionLabel(actionTitle)
                        .textFont(.caption, weight: .semibold)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .frame(minHeight: 54)
        .noticeCapsule(tone)
        .shadow(color: Palette.shadow.opacity(0.5), radius: 20, y: 10)
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
        case .info: Palette.accent
        case .error: Palette.rose
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        NoticeBanner("ランチ ¥980 を記録しました", systemImage: "checkmark", actionTitle: "取り消す") {}
        NoticeBanner("名前を入れてください", systemImage: "exclamationmark", tone: .error)
    }
    .padding()
    .background(Palette.background)
}
