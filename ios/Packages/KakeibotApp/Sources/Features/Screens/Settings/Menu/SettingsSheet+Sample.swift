#if DEBUG
import DesignSystem
import SwiftUI

extension SettingsSheet {
    var sampleSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("開発")

            Button {
                isConfirmingSample = true
            } label: {
                row("テストデータを入れる", systemImage: "wand.and.stars")
            }
            .buttonStyle(.plain)
            .disabled(isInsertingSample)
            .padding(.horizontal, 16)
            .card()
            .confirmationDialog(
                "4 か月分の記録・予算・テンプレート・固定費を足します",
                isPresented: $isConfirmingSample,
                titleVisibility: .visible
            ) {
                Button("足す") {
                    Task {
                        await insertSample()
                    }
                }
            }

            if isInsertingSample {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }

            if let sampleMessage {
                Text(sampleMessage)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .padding(.leading, 8)
            }
        }
    }
}

private extension SettingsSheet {
    func insertSample() async {
        isInsertingSample = true
        sampleMessage = nil

        do {
            try await SettingsSampleData.insert(into: database, today: today, now: Date())
            sampleMessage = "テストデータを入れました"
        } catch {
            sampleMessage = "テストデータを入れられませんでした"
        }

        isInsertingSample = false
    }
}
#endif
