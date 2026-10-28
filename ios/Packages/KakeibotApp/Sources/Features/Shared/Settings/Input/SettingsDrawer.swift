import DesignSystem
import SwiftUI

struct SettingsDrawer<Content: View>: View {
    @Environment(\.themeStyle.corner) private var corner

    private let title: String
    private let showsDone: Bool
    private let onDone: () -> Void
    private let content: Content

    init(
        _ title: String,
        showsDone: Bool = true,
        onDone: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.showsDone = showsDone
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

                if showsDone {
                    RingButton(
                        systemImage: "checkmark",
                        style: .prominent,
                        action: onDone
                    )
                }
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
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}

private extension SettingsDrawer {
    var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(28))
    }
}

extension AnyTransition {
    static var settingsDrawer: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}
