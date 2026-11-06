import SwiftUI

public extension View {
    func errorBanner(
        _ notice: ErrorNotice,
        bottom: CGFloat = NoticeBanner.bottomMargin,
        onClear: @escaping () -> Void
    ) -> some View {
        modifier(
            ErrorBanner(
                notice: notice,
                bottom: bottom,
                onClear: onClear
            )
        )
    }
}

public extension NoticeBanner {
    nonisolated static let bottomMargin: CGFloat = 12
    nonisolated static let sideMargin: CGFloat = 16
}

public extension EnvironmentValues {
    @Entry var noticeRound = 0
}

private struct ErrorBanner: ViewModifier {
    @Environment(\.noticeRound) private var noticeRound

    let notice: ErrorNotice
    let bottom: CGFloat
    let onClear: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = notice.message {
                    NoticeBanner(message, systemImage: systemImage, tone: notice.tone)
                        .padding(.horizontal, NoticeBanner.sideMargin)
                        .padding(.bottom, bottom)
                        .onTapGesture(perform: onClear)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: notice.message)
            .haptic(.error, trigger: notice.count) { _, _ in
                notice.tone == .error
            }
            .task(id: notice.count) {
                guard notice.count > 0, await (try? Task.sleep(for: Self.duration)) != nil else {
                    return
                }

                onClear()
            }
            .onChange(of: noticeRound) {
                if notice.message != nil {
                    onClear()
                }
            }
    }
}

private extension ErrorBanner {
    static let duration = Duration.seconds(6)

    var systemImage: String {
        switch notice.tone {
        case .info: "info"
        case .error: "exclamationmark"
        }
    }
}
