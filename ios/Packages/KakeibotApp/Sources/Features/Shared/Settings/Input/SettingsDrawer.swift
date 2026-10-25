import DesignSystem
import SwiftUI

struct SettingsDrawer<Content: View>: View {
    private let title: String
    private let isFloating: Bool
    private let onDone: () -> Void
    private let content: Content

    init(
        _ title: String,
        isFloating: Bool = false,
        onDone: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isFloating = isFloating
        self.onDone = onDone
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .textFont(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                Spacer()

                RingButton(
                    systemImage: "checkmark",
                    style: .prominent,
                    action: onDone
                )
            }

            content
        }
        .geometryGroup()
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background {
            shape
                .fill(Palette.panel)
                .overlay {
                    shape
                        .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                }
                .ignoresSafeArea(edges: ignoredEdges)
        }
    }
}

private extension SettingsDrawer {
    var ignoredEdges: Edge.Set {
        isFloating ? [] : .bottom
    }

    var shape: UnevenRoundedRectangle {
        let bottom: CGFloat = isFloating ? 28 : 0

        return UnevenRoundedRectangle(
            topLeadingRadius: 28,
            bottomLeadingRadius: bottom,
            bottomTrailingRadius: bottom,
            topTrailingRadius: 28
        )
    }
}

extension AnyTransition {
    static var settingsDrawer: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}
