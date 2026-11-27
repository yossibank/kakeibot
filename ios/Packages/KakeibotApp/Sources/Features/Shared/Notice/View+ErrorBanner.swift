import DesignSystem
import FeatureModels
import SwiftUI

public extension View {
    func errorBanner(
        _ notice: ErrorNotice,
        bottom: CGFloat = NoticeBanner.bottomMargin
    ) -> some View {
        modifier(ErrorBanner(notice: notice, bottom: bottom))
    }
}

private struct ErrorBanner: ViewModifier {
    @Environment(\.noticeRound) private var noticeRound

    let notice: ErrorNotice
    let bottom: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = notice.message {
                    NoticeBanner(message, systemImage: systemImage, tone: notice.tone)
                        .padding(.horizontal, NoticeBanner.sideMargin)
                        .padding(.bottom, bottom)
                        .onTapGesture {
                            notice.clear()
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: notice.message)
            .haptic(.error, trigger: notice.count) { _, _ in
                notice.tone == .error
            }
            .onChange(of: noticeRound) {
                if notice.message != nil {
                    notice.clear()
                }
            }
    }
}

private extension ErrorBanner {
    var systemImage: String {
        switch notice.tone {
        case .info: "info"
        case .error: "exclamationmark"
        }
    }
}
