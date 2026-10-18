import SwiftUI

public extension View {
    func errorBanner(
        _ message: String?,
        count: Int,
        bottom: CGFloat = 12,
        onClear: @escaping () -> Void
    ) -> some View {
        modifier(
            ErrorBanner(
                message: message,
                count: count,
                bottom: bottom,
                onClear: onClear
            )
        )
    }
}

private struct ErrorBanner: ViewModifier {
    let message: String?
    let count: Int
    let bottom: CGFloat
    let onClear: () -> Void

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
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
            .animation(.snappy, value: message)
            .sensoryFeedback(.error, trigger: count)
            .task(id: count) {
                guard count > 0 else {
                    return
                }

                guard await (try? Task.sleep(for: .seconds(3))) != nil else {
                    return
                }

                onClear()
            }
    }
}
