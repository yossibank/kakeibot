import Core
import DesignSystem
import SwiftUI

public struct WhatsNewSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var model: WhatsNewModel

    private let revealsSteps: Bool
    private let onTry: (WhatsNewRelease.Action) -> Void

    public init(
        seenVersion: String?,
        version: String = WhatsNewRelease.latestVersion,
        revealsSteps: Bool = true,
        onTry: @escaping (WhatsNewRelease.Action) -> Void
    ) {
        let model = WhatsNewModel(seenVersion: seenVersion, version: version)

        _model = State(initialValue: model)

        self.revealsSteps = revealsSteps
        self.onTry = onTry
    }

    public var body: some View {
        VStack(spacing: 16) {
            header

            versionPicker

            ScrollViewReader { proxy in
                ScrollView {
                    if let release = model.output.release {
                        section(release) { id in
                            withAnimation(.smooth) {
                                proxy.scrollTo(id, anchor: .top)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .id(model.state.fields.version)
                .transition(.opacity)
                .scrollIndicators(.hidden)
                .contentMargins(.horizontal, 20, for: .scrollContent)
                .padding(.horizontal, -20)
            }
            .animation(.snappy, value: model.state.fields.version)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .backdrop()
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

    var versionPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(WhatsNewRelease.all) { release in
                    versionChip(release)
                }
            }
            .padding(.vertical, 2)
        }
        .haptic(.selection, trigger: model.state.fields.version)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, 20, for: .scrollContent)
        .padding(.horizontal, -20)
    }

    func versionChip(_ release: WhatsNewRelease) -> some View {
        let isSelected = release.version == model.state.fields.version

        return Button {
            model.state.choose(release.version)
        } label: {
            HStack(spacing: 8) {
                Text(release.version)
                    .textFont(.subheadline, weight: isSelected ? .bold : .medium)
                    .monospacedDigit()

                if model.output.isNew(release) {
                    Circle()
                        .fill(isSelected ? Palette.backgroundTop : Palette.rose)
                        .frame(width: 8, height: 8)
                }
            }
            .foregroundStyle(isSelected ? Palette.backgroundTop : Palette.accentStrong)
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(
                isSelected ? AnyShapeStyle(Palette.accent) : AnyShapeStyle(Palette.card),
                in: .capsule
            )
            .overlay {
                Capsule()
                    .stroke(Palette.outline, lineWidth: isSelected ? 0 : 0.8)
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }

    func section(
        _ release: WhatsNewRelease,
        onJump: @escaping (String) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(release.features.count) つの新しいこと")
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)

                Text(release.month)
                    .textFont(.caption2)
                    .foregroundStyle(Palette.subtext)

                Spacer(minLength: 0)
            }

            RowOrColumnLayout(rowSpacing: 8, columnSpacing: 8) {
                chips(release, onJump: onJump)
            }
        }
        .padding(16)
        .background(Palette.lit.opacity(.subtle), in: .rect(cornerRadius: 20))
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
                    .padding(.horizontal, 8)
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
