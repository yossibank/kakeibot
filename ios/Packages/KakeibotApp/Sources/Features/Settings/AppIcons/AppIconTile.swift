import DesignSystem
import SwiftUI

struct AppIconTile: View {
    @State private var taps = 0

    let choice: AppIconChoice
    let isCurrent: Bool
    let onSelect: () -> Void

    var body: some View {
        let ring = isCurrent ? Palette.accent : Color.clear
        let titleColor = isCurrent ? Palette.accentStrong : Palette.subtext

        Button {
            guard !isCurrent else {
                return
            }

            taps += 1
            onSelect()
        } label: {
            VStack(spacing: 8) {
                preview
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(ring, lineWidth: 2)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isCurrent {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(
                                    Palette.accent,
                                    Palette.background
                                )
                                .offset(x: 6, y: 6)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.3), value: isCurrent)

                Text(choice.title)
                    .font(.footnote)
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension AppIconTile {
    struct Pop {
        var scale = 1.0
        var ring = 1.0
        var glow = 0.0
    }

    var preview: some View {
        AppIconPreview(choice: choice, size: Self.size)
            .keyframeAnimator(
                initialValue: Pop(),
                trigger: taps
            ) { content, pop in
                content
                    .scaleEffect(pop.scale)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Palette.accent, lineWidth: 2)
                            .scaleEffect(pop.ring)
                            .opacity(pop.glow)
                    }
            } keyframes: { _ in
                KeyframeTrack(\.scale) {
                    SpringKeyframe(0.88, duration: 0.12)
                    SpringKeyframe(1.08, duration: 0.18)
                    SpringKeyframe(1, duration: 0.25)
                }
                KeyframeTrack(\.ring) {
                    LinearKeyframe(1, duration: 0.12)
                    CubicKeyframe(1.45, duration: 0.45)
                }
                KeyframeTrack(\.glow) {
                    LinearKeyframe(1, duration: 0.12)
                    CubicKeyframe(0, duration: 0.45)
                }
            }
    }
}

private extension AppIconTile {
    static let size: CGFloat = 76
}
