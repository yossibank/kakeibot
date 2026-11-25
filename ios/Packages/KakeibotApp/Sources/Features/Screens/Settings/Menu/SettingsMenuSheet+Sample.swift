#if DEBUG
import DesignSystem
import FeatureModels
import SwiftUI

extension SettingsMenuSheet {
    var sampleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("開発")

            Button {
                sample.state.isConfirming = true
            } label: {
                row("テストデータを入れる", systemImage: "wand.and.stars")
            }
            .buttonStyle(.plain)
            .disabled(sample.state.progress == .inserting)
            .padding(.horizontal, 16)
            .card()
            .confirmationDialog(
                "4 か月分の記録・予算・テンプレート・固定費を足します",
                isPresented: Bindable(sample.state).isConfirming,
                titleVisibility: .visible
            ) {
                Button("足す") {
                    sample.perform { [today] in
                        await $0.insert(today: today)
                    }
                }
            }

            if sample.state.progress == .inserting {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            if let message = sample.state.progress?.message {
                Text(message)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.leading, 8)
            }
        }
    }
}
#endif
