import Core
import DesignSystem
import SwiftUI

public struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let seenVersion: String?
    private let revealsSteps: Bool
    private let onTry: (WhatsNewRelease.Action) -> Void

    public init(
        seenVersion: String?,
        revealsSteps: Bool = true,
        onTry: @escaping (WhatsNewRelease.Action) -> Void
    ) {
        self.seenVersion = seenVersion
        self.revealsSteps = revealsSteps
        self.onTry = onTry
    }

    public var body: some View {
        VStack(spacing: 16) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        ForEach(WhatsNewRelease.all) { release in
                            section(release) { id in
                                withAnimation(.smooth) {
                                    proxy.scrollTo(id, anchor: .top)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .padding(.horizontal, -20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
    }
}

private extension WhatsNewSheet {
    func isNew(_ release: WhatsNewRelease) -> Bool {
        AppVersion.isNewer(release.version, than: seenVersion)
    }
}

private extension WhatsNewSheet {
    var header: some View {
        ZStack {
            SheetTitle("お知らせ")

            HStack {
                RingButton(systemImage: "xmark") {
                    dismiss()
                }

                Spacer()
            }
        }
    }

    func section(
        _ release: WhatsNewRelease,
        onJump: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            summary(release, onJump: onJump)

            ForEach(release.features) { feature in
                WhatsNewCard(
                    feature: feature,
                    revealsSteps: revealsSteps,
                    onTry: onTry
                )
                .id(feature.id)
            }
        }
    }

    func summary(
        _ release: WhatsNewRelease,
        onJump: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(release.version)
                    .displayFont(.title, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(release.features.count) つの新しいこと")
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.text)

                    Text(release.month)
                        .textFont(.caption2)
                        .foregroundStyle(Palette.subtext)
                }

                Spacer(minLength: 0)

                if isNew(release) {
                    Text("NEW")
                        .textFont(.caption2, weight: .bold)
                        .tracking(1)
                        .foregroundStyle(Palette.backgroundTop)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Palette.accent, in: .capsule)
                }
            }

            RowOrColumnLayout(rowSpacing: 8, columnSpacing: 8) {
                chips(release, onJump: onJump)
            }
        }
        .padding(16)
        .background(Palette.accent.opacity(.subtle), in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Palette.outline, lineWidth: 1)
        }
    }

    func chips(
        _ release: WhatsNewRelease,
        onJump: @escaping (String) -> Void
    ) -> some View {
        ForEach(release.features) { feature in
            Button {
                onJump(feature.id)
            } label: {
                Label(feature.shortTitle, systemImage: feature.systemImage)
                    .textFont(.caption, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)
                    .lineLimit(1)
                    .fixedSize()
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(Palette.card, in: .capsule)
                    .overlay {
                        Capsule()
                            .stroke(Palette.outline, lineWidth: 0.8)
                    }
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    WhatsNewSheet(seenVersion: nil) { _ in }
}
