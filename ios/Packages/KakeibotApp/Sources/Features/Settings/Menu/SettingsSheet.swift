import Core
import DesignSystem
import Store
import SwiftUI

struct SettingsSheet: View {
    @State private var monthStartDay: MonthStartDay = .first

    @Environment(\.dismiss) private var dismiss

    let database: AppDatabase

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("入力")

                    VStack(spacing: 0) {
                        NavigationLink {
                            WalletListView(database: database)
                        } label: {
                            row("口座", systemImage: "building.columns")
                        }

                        Rectangle()
                            .fill(Palette.gold.opacity(0.1))
                            .frame(height: 0.5)

                        NavigationLink {
                            CategoryListView(database: database)
                        } label: {
                            row("カテゴリ", systemImage: "tag")
                        }

                        Rectangle()
                            .fill(Palette.gold.opacity(0.1))
                            .frame(height: 0.5)

                        NavigationLink {
                            TemplateListView(database: database)
                        } label: {
                            row("テンプレート", systemImage: "rectangle.stack")
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 14)
                    .card()
                }

                VStack(alignment: .leading, spacing: 6) {
                    sectionTitle("期間")

                    NavigationLink {
                        MonthStartDayView(
                            model: MonthStartDayModel(
                                database: database,
                                today: LocalDate(Date(), in: .current)
                            )
                        )
                    } label: {
                        row(
                            "月の始まり",
                            systemImage: "calendar",
                            value: PeriodText.startDay(monthStartDay)
                        )
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
        .task {
            await observeMonthStartDay()
        }
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

    func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption2)
            .tracking(3)
            .foregroundStyle(Palette.gold)
            .padding(.leading, 6)
    }

    func row(
        _ title: String,
        systemImage: String,
        value: String? = nil
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

            if let value {
                Text(value)
                    .font(.footnote)
                    .foregroundStyle(Palette.mist)
            }

            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Palette.dusk)
        }
        .frame(minHeight: 48)
        .contentShape(.rect)
    }
}

private extension SettingsSheet {
    func observeMonthStartDay() async {
        do {
            for try await startDay in database.monthStartDayUpdates() {
                monthStartDay = startDay
            }
        } catch {
            monthStartDay = .first
        }
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        let _ = try? database.insertDefaultsIfEmpty(at: Date())
        SettingsSheet(database: database)
    }
}
