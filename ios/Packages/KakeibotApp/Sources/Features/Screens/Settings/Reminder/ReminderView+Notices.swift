import Core
import DesignSystem
import SwiftUI

extension ReminderView {
    var recurringText: String {
        let time = model.time ?? .morning

        return "固定費の通知は \(time) に届きます"
    }

    var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle("届く通知")

            HStack(spacing: 4) {
                dayStepButton("chevron.left", by: -1)

                ForEach(Self.days, id: \.self) { day in
                    dayButton(day)
                }

                dayStepButton("chevron.right", by: 1)
            }

            notificationCard
                .padding(12)
                .background(wallpaper, in: cardShape)
        }
    }

    var recurringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle("固定費の通知")

            VStack(spacing: 0) {
                ForEach(model.upcomingNotices, id: \.self) { notice in
                    noticeRow(notice)
                }
            }
            .padding(.horizontal, 16)
            .card()
        }
    }
}

private extension ReminderView {
    var notificationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "yensign")
                .sansFont(.body, weight: .medium)
                .foregroundStyle(Palette.cardBottom)
                .frame(width: 38, height: 38)
                .background(
                    Palette.accent,
                    in: .rect(cornerRadius: corner.radius(8))
                )

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("かけいぼっと")
                        .textFont(.caption2, weight: .semibold)
                        .foregroundStyle(Palette.text.opacity(.strong))

                    Spacer()

                    Text(timeText)
                        .textFont(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(Palette.subtext)
                }

                Text(model.previewMessage.title)
                    .textFont(.subheadline, weight: .semibold)
                    .foregroundStyle(Palette.text)
                    .contentTransition(.opacity)

                Text(model.previewMessage.body)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.text.opacity(.strong))
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: bubbleShape)
        .shadow(color: Palette.shadow.opacity(.muted), radius: 12, y: 4)
    }

    func dayButton(_ day: Weekday) -> some View {
        let isSelected = model.previewDay == day
        let color = isSelected ? Palette.accentStrong : Palette.subtext
        let weight: Font.Weight = isSelected ? .semibold : .regular

        return Button {
            model.showPreview(on: day)
        } label: {
            Text(day.shortName)
                .textFont(.caption, weight: weight)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(SettingsTile.fill(isSelected: isSelected), in: Capsule())
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    func dayStepButton(
        _ systemImage: String,
        by step: Int
    ) -> some View {
        Button {
            showPreview(by: step)
        } label: {
            Image(systemName: systemImage)
                .sansFont(.micro, weight: .semibold)
                .foregroundStyle(Palette.accent)
                .frame(width: 24, height: 32)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    func noticeRow(_ notice: PlannedNotification) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(notice.date.month)/\(notice.date.day) \(notice.time.description)")
                .textFont(.caption)
                .monospacedDigit()
                .foregroundStyle(Palette.accent)
                .frame(width: 84, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(notice.title)
                    .textFont(.subheadline)
                    .foregroundStyle(Palette.text)

                Text(notice.body)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }
}

private extension ReminderView {
    static let days: [Weekday] = [
        .monday,
        .tuesday,
        .wednesday,
        .thursday,
        .friday,
        .saturday,
        .sunday
    ]

    var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(24))
    }

    var bubbleShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(16))
    }

    var wallpaper: LinearGradient {
        LinearGradient(
            colors: [
                Palette.accent.opacity(.muted),
                Palette.rose.opacity(.soft),
                Palette.accentDeep.opacity(.soft)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    func showPreview(by step: Int) {
        let index = Self.days.firstIndex(of: model.previewDay) ?? 0
        let next = (index + step + Self.days.count) % Self.days.count

        model.showPreview(on: Self.days[next])
    }
}
