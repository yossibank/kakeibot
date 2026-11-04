import DesignSystem
import SwiftUI

struct RecurringPresetStrip: View {
    let presets: [RecurringPreset]
    let onSelect: (RecurringPreset) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    presetButton(preset)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
        .scrollBounceBehavior(.basedOnSize)
    }
}

private extension RecurringPresetStrip {
    func presetButton(_ preset: RecurringPreset) -> some View {
        Button {
            onSelect(preset)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: preset.systemImage)
                    .sansFont(.small)
                    .foregroundStyle(Palette.accent)

                Text(preset.title)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.accentStrong)
                    .fixedSize()
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 40)
            .background(SettingsTile.fill(isSelected: false), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(SettingsTile.stroke(isSelected: false), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
