import DesignSystem
import Store
import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) private var dismiss

    let database: AppDatabase

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 6) {
                    Text("入力")
                        .font(.caption2)
                        .tracking(3)
                        .foregroundStyle(Palette.gold)
                        .padding(.leading, 6)

                    NavigationLink {
                        CategoryListView(database: database)
                    } label: {
                        row("カテゴリ", systemImage: "tag")
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .card()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                Rectangle()
                    .fill(Palette.night)
                    .ignoresSafeArea()
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

private extension SettingsSheet {
    var header: some View {
        HStack {
            Color.clear
                .frame(width: 44, height: 44)

            Spacer()

            Text("設定")
                .font(.system(size: 16, design: .serif))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            RingButton(systemImage: "xmark") {
                dismiss()
            }
        }
    }

    func row(
        _ title: String,
        systemImage: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Palette.gold)
                .frame(width: 22)

            Text(title)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.dusk)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        SettingsSheet(database: database)
    }
}
