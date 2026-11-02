import Core
import DesignSystem
import SwiftUI

public struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let seenVersion: String?
    private let onTry: (WhatsNewRelease.Action) -> Void

    public init(
        seenVersion: String?,
        onTry: @escaping (WhatsNewRelease.Action) -> Void
    ) {
        self.seenVersion = seenVersion
        self.onTry = onTry
    }

    public var body: some View {
        VStack(spacing: 16) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    ForEach(WhatsNewRelease.all) { release in
                        section(release)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .padding(.horizontal, -20)
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
    static let artHeight: CGFloat = 132
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

    func section(_ release: WhatsNewRelease) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(release.version)
                    .displayFont(.body, weight: .medium)
                    .foregroundStyle(Palette.accentStrong)

                Text(release.month)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)

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

            ForEach(release.features) { feature in
                card(feature)
            }
        }
    }

    func card(_ feature: WhatsNewRelease.Feature) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureArt(kind: feature.art)
                .frame(height: Self.artHeight)

            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .textFont(.headline)
                    .foregroundStyle(Palette.text)

                Text(feature.text)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let action = feature.action {
                CardButton(
                    feature.actionTitle,
                    style: .outlined(Palette.accent),
                    height: 40
                ) {
                    onTry(action)
                }
            }
        }
        .padding(16)
        .card()
    }
}

#Preview {
    WhatsNewSheet(seenVersion: nil) { _ in }
}
