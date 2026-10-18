import SwiftUI

public extension View {
    func errorBanner(
        _ notice: ErrorNotice,
        bottom: CGFloat = 12,
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

private struct ErrorBanner: ViewModifier {
    let notice: ErrorNotice
    let bottom: CGFloat
    let onClear: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message = notice.message {
                    NoticeBanner(
                        message,
                        systemImage: "exclamationmark",
                        tone: .error
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.snappy, value: notice.message)
            .sensoryFeedback(.error, trigger: notice.count)
            .task(id: notice.count) {
                guard notice.count > 0 else {
                    return
                }

                guard await (try? Task.sleep(for: .seconds(3))) != nil else {
                    return
                }

                onClear()
            }
    }
}
