import DesignSystem
import SwiftUI

struct SettingsDrawer<Content: View>: View {
    private let title: String
    private let onDone: () -> Void
    private let content: Content

    init(
        _ title: String,
        onDone: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.onDone = onDone
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.gold)

                Spacer()

                RingButton(
                    systemImage: "checkmark",
                    style: .prominent,
                    action: onDone
                )
            }

            content
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background {
            Self.shape
                .fill(Palette.drawer)
                .overlay {
                    Self.shape
                        .stroke(Palette.gold.opacity(.muted), lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

private extension SettingsDrawer {
    static var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
    }
}

extension AnyTransition {
    static var settingsDrawer: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}
