import Core
import DesignSystem
import Store
import SwiftUI

public struct ThemeListView: View {
    @State private var model: ThemeListModel

    @Environment(\.dismiss) private var dismiss

    public init(database: AppDatabase) {
        _model = State(initialValue: ThemeListModel(database: database))
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    section("ダーク", isLight: false)

                    section("ライト", isLight: true)
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Rectangle()
                .fill(Palette.background)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.selection, trigger: model.current)
        .task {
            await model.load()
        }
    }
}

private extension ThemeListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("テーマ")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    func section(
        _ title: String,
        isLight: Bool
    ) -> some View {
        let presets = ThemePreset.allCases.filter { preset in
            preset.palette.isLight == isLight
        }

        return VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.caption2)
                .tracking(3)
                .foregroundStyle(Palette.accent)
                .padding(.leading, 6)

            LazyVGrid(columns: Self.columns, spacing: 18) {
                ForEach(presets, id: \.self) { preset in
                    tile(preset)
                }
            }
        }
    }

    func tile(_ preset: ThemePreset) -> some View {
        let isCurrent = preset == model.current
        let ring = isCurrent ? Palette.accent : Color.clear
        let titleColor = isCurrent ? Palette.accentStrong : Palette.subtext

        return Button {
            Task {
                await model.select(preset)
            }
        } label: {
            VStack(spacing: 8) {
                ThemePreview(preset: preset)
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
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

                Text(preset.title)
                    .font(.footnote)
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension ThemeListView {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )
}
