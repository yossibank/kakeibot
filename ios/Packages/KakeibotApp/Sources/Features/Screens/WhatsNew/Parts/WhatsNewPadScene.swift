import DesignSystem
import SwiftUI

struct WhatsNewPadScene: View {
    let step: Step

    var body: some View {
        switch step {
        case .review:
            tablet {
                review
            }

        case .keyboard:
            keyboard

        case .home:
            tablet {
                home
            }
        }
    }
}

extension WhatsNewPadScene {
    enum Step: Hashable, Sendable {
        case home
        case review
        case keyboard
    }
}

private extension WhatsNewPadScene {
    static let keys = ["1", "2", "8", "0"]

    var sidebar: some View {
        VStack(alignment: .leading, spacing: 4) {
            Capsule()
                .fill(Palette.accent.opacity(.medium))
                .frame(width: 16, height: 4)

            ForEach(0..<2, id: \.self) { _ in
                Capsule()
                    .fill(Palette.hairline)
                    .frame(width: 16, height: 4)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 18)
    }

    var home: some View {
        HStack(alignment: .top, spacing: 4) {
            VStack(spacing: 4) {
                block(height: 44) {
                    Circle()
                        .trim(from: 0.1, to: 0.65)
                        .stroke(Palette.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(108))
                        .frame(width: 30, height: 30)
                }

                block(height: 26) {
                    lines(2)
                }
            }

            VStack(spacing: 4) {
                block(height: 26) {
                    lines(2)
                }

                block(height: 44) {
                    lines(4)
                }
            }
        }
    }

    var review: some View {
        HStack(alignment: .top, spacing: 4) {
            VStack(spacing: 4) {
                block(height: 30) {
                    lines(2)
                }

                block(height: 40) {
                    lines(3)
                }
            }

            block(height: 74) {
                Circle()
                    .trim(from: 0, to: 0.62)
                    .stroke(Palette.accent, lineWidth: 8)
                    .background {
                        Circle()
                            .stroke(Palette.accent.opacity(.subtle), lineWidth: 8)
                    }
                    .rotationEffect(.degrees(-90))
                    .frame(width: 38, height: 38)
            }
        }
    }

    var keyboard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Text("金額")
                    .textFont(size: .micro, weight: .semibold)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 2)

                AmountText(1280, font: .size(.headline, weight: .bold), color: Palette.accentStrong)
            }
            .padding(.horizontal, 8)
            .frame(height: 36)
            .card(cornerRadius: 12)

            HStack(spacing: 4) {
                ForEach(Self.keys, id: \.self) { key in
                    Text(key)
                        .textFont(size: .caption, weight: .semibold)
                        .foregroundStyle(Palette.text)
                        .frame(width: 26, height: 26)
                        .background(Palette.card, in: .rect(cornerRadius: 4))
                        .overlay {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Palette.hairline, lineWidth: 1)
                        }
                }
            }

            Image(systemName: "keyboard")
                .font(.system(size: 22))
                .foregroundStyle(Palette.accent)
        }
        .padding(.horizontal, 4)
    }

    func tablet(@ViewBuilder _ content: () -> some View) -> some View {
        HStack(alignment: .top, spacing: 4) {
            sidebar

            content()
        }
        .padding(8)
        .frame(width: 128, height: 92)
        .background(Palette.card, in: .rect(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(Palette.text.opacity(.medium), lineWidth: 3)
        }
    }

    func block(
        height: CGFloat,
        @ViewBuilder content: () -> some View
    ) -> some View {
        content()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(Palette.faint, in: .rect(cornerRadius: 4))
    }

    func lines(_ count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<count, id: \.self) { index in
                let width: CGFloat = index.isMultiple(of: 2) ? 28 : 20

                Capsule()
                    .fill(Palette.hairline)
                    .frame(width: width, height: 3)
            }
        }
    }
}
