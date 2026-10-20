import Core
import DesignSystem
import Store
import SwiftUI
import UIKit

public struct ReminderView: View {
    @State private var model: ReminderModel
    @State private var isPickingTime = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.themeStyle.corner) private var corner

    public init(model: ReminderModel) {
        _model = State(initialValue: model)
        _isPickingTime = State(initialValue: model.isCustom)
    }

    public var body: some View {
        VStack(spacing: 18) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    hero

                    if model.isDenied {
                        deniedCard
                            .transition(.opacity)
                    }

                    if model.isOn {
                        timeSection
                            .transition(.opacity)

                        previewSection
                            .transition(.opacity)
                    }

                    recurringNote
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
        .animation(.snappy, value: model.time)
        .animation(.snappy, value: model.isDenied)
        .animation(.snappy, value: isPickingTime)
        .sensoryFeedback(.selection, trigger: model.time)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task {
                    await model.refreshAuthorization()
                }
            }
        }
        .task {
            await model.load()
        }
    }
}

private extension ReminderView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("通知")
                .displayFont(.body)
                .tracking(4)
                .foregroundStyle(Palette.accent)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: bellImage)
                .font(.sans(.headline, weight: .light))
                .foregroundStyle(Palette.accent)
                .frame(width: 48, height: 48)
                .background(Palette.accent.opacity(.subtle), in: Circle())
                .contentTransition(.symbolEffect(.replace))

            VStack(spacing: 6) {
                Text("記録忘れの通知")
                    .textFont(.caption2)
                    .tracking(3)
                    .foregroundStyle(Palette.accent)

                Text(timeText)
                    .displayFont(.display)
                    .monospacedDigit()
                    .foregroundStyle(timeColor)
                    .contentTransition(.numericText())

                Text(summaryText)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .multilineTextAlignment(.center)
            }

            CapsulePicker(selection: onBinding, options: Self.onOptions)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .card(cornerRadius: 22)
    }

    var deniedCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("通知が許可されていません", systemImage: "bell.slash")
                .textFont(.subheadline, weight: .semibold)
                .foregroundStyle(Palette.rose)

            Text("設定アプリで Kakeibot の通知を許可すると届きます")
                .textFont(.caption)
                .foregroundStyle(Palette.subtext)

            Button {
                openSettings()
            } label: {
                Text("設定アプリを開く")
                    .textFont(.footnote, weight: .semibold)
                    .foregroundStyle(Palette.accentStrong)
                    .frame(maxWidth: .infinity, minHeight: 40)
                    .background(Palette.rose.opacity(.subtle), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Palette.rose.opacity(.medium), lineWidth: 1)
                    }
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.rose.opacity(.faint), in: cardShape)
        .overlay {
            cardShape
                .stroke(Palette.rose.opacity(.muted), lineWidth: 1)
        }
    }

    var timeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionTitle("時刻")

            LazyVGrid(columns: Self.columns, spacing: 8) {
                ForEach(ReminderModel.presets, id: \.self) { time in
                    let isSelected = !isPickingTime && model.time == time

                    SettingsChoice(time.description, isSelected: isSelected) {
                        isPickingTime = false

                        Task {
                            await model.choose(time)
                        }
                    }
                }

                SettingsChoice("ほかの時刻", isSelected: isPickingTime) {
                    isPickingTime = true
                }
            }

            if isPickingTime {
                DatePicker(
                    "時刻",
                    selection: dateBinding,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .clipped()
                .card(cornerRadius: 22)
                .transition(.opacity)
            }
        }
    }

    var previewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionTitle("届く通知")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "yensign")
                    .font(.sans(.body, weight: .medium))
                    .foregroundStyle(Palette.cardBottom)
                    .frame(width: 38, height: 38)
                    .background(
                        Palette.accent,
                        in: .rect(cornerRadius: corner.radius(9))
                    )

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Kakeibot")
                            .textFont(.caption2)
                            .foregroundStyle(Palette.subtext)

                        Spacer()

                        Text(timeText)
                            .textFont(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Palette.subtext)
                    }

                    Text(NotificationPlan.reminderTitle)
                        .textFont(.subheadline, weight: .semibold)
                        .foregroundStyle(Palette.text)

                    Text(NotificationPlan.reminderBody)
                        .textFont(.footnote)
                        .foregroundStyle(Palette.text.opacity(.strong))
                }
            }
            .padding(14)
            .background(Palette.text.opacity(.faint), in: cardShape)
            .overlay {
                cardShape
                    .stroke(Palette.text.opacity(.subtle), lineWidth: 1)
            }

            Text("記録か「支出なし」の印がある日は届きません")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .padding(.leading, 6)
        }
    }

    var recurringNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            SettingsSectionTitle("固定費の通知")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "repeat")
                    .font(.sans(.small))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 28, height: 28)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                Text(recurringText)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(cornerRadius: 18)

            if !model.upcomingNotices.isEmpty {
                VStack(spacing: 0) {
                    ForEach(model.upcomingNotices, id: \.self) { notice in
                        noticeRow(notice)
                    }
                }
                .padding(.horizontal, 14)
                .card(cornerRadius: 18)
            }
        }
    }

    func noticeRow(_ notice: PlannedNotification) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(notice.date.month)/\(notice.date.day) \(notice.time)")
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
    static let onOptions: [CapsulePicker<Bool>.Option] = [
        .init("オフ", value: false),
        .init("オン", value: true)
    ]

    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 8),
        count: 3
    )

    var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner.radius(18))
    }

    var bellImage: String {
        model.isOn ? "bell.badge" : "bell.slash"
    }

    var timeText: String {
        model.time?.description ?? "オフ"
    }

    var timeColor: Color {
        model.isOn ? Palette.accentStrong : Palette.hint
    }

    var summaryText: String {
        guard let time = model.time else {
            return "記録を忘れても知らせません"
        }

        return "毎日 \(time) に、記録のない日だけ知らせます"
    }

    var recurringText: String {
        let time = model.time ?? .morning
        let head = "固定費ごとに「前に知らせる」を決めると届きます。"
        return head + "時刻は \(time) です"
    }

    var onBinding: Binding<Bool> {
        Binding {
            model.isOn
        } set: { isOn in
            Task {
                await model.setOn(isOn)
            }
        }
    }

    var dateBinding: Binding<Date> {
        Binding {
            let time = model.time ?? .evening

            let components = DateComponents(
                hour: time.hour,
                minute: time.minute
            )

            return Calendar.current.date(from: components) ?? Date()
        } set: { date in
            let parts = Calendar.current.dateComponents(
                [.hour, .minute],
                from: date
            )

            let time = ReminderTime(
                hour: parts.hour ?? 21,
                minute: parts.minute ?? 0
            )

            Task {
                await model.choose(time)
            }
        }
    }

    func openSettings() {
        let link = UIApplication.openNotificationSettingsURLString

        guard let url = URL(string: link) else {
            return
        }

        openURL(url)
    }
}

#Preview {
    if let database = try? AppDatabase.inMemory() {
        NavigationStack {
            ReminderView(
                model: ReminderModel(
                    database: database,
                    today: LocalDate(Date(), in: .current),
                    time: .evening,
                    permission: .allowed
                )
            )
        }
    }
}
