import Core
import DesignSystem
import Store
import SwiftUI
import UIKit

public struct ReminderView: View {
    @State private var model: ReminderModel
    @State private var isPickingTime = false

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.themeStyle.corner) private var corner

    public init(model: ReminderModel) {
        _model = State(initialValue: model)
        _isPickingTime = State(initialValue: model.isCustom)
    }

    public var body: some View {
        VStack(spacing: 20) {
            SettingsBackHeader("通知")

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(spacing: 12) {
                        hero

                        if model.isDenied {
                            deniedBanner
                                .transition(.opacity)
                        }
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
        .padding(.horizontal, 20)
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
        .animation(.snappy, value: model.previewDay)
        .transaction(value: model.isLoaded) { transaction in
            transaction.disablesAnimations = true
        }
        .sensoryFeedback(.selection, trigger: model.time)
        .sensoryFeedback(.selection, trigger: model.previewDay)
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
    var hero: some View {
        VStack(spacing: 12) {
            Image(systemName: bellImage)
                .sansFont(.headline, weight: .light)
                .foregroundStyle(Palette.accent)
                .frame(width: 48, height: 48)
                .background(Palette.accent.opacity(.subtle), in: Circle())
                .contentTransition(.symbolEffect(.replace))
                .symbolEffect(
                    .wiggle,
                    options: .repeat(.periodic(delay: 4)),
                    isActive: model.isOn
                )

            Text(timeText)
                .displayFont(.display)
                .monospacedDigit()
                .foregroundStyle(timeColor)
                .contentTransition(.numericText())

            HStack(spacing: 12) {
                Text(summaryText)
                    .textFont(.caption)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                CapsulePicker(selection: onBinding, options: Self.onOptions)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .card()
    }

    var deniedBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .sansFont(.small)

            Text("通知が届かない状態です")
                .textFont(.footnote, weight: .semibold)

            Spacer(minLength: 0)

            Button {
                openSettings()
            } label: {
                HStack(spacing: 2) {
                    Text("許可する")
                        .textFont(.caption, weight: .semibold)

                    Image(systemName: "chevron.right")
                        .sansFont(.micro, weight: .semibold)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 30)
                .background(Palette.rose.opacity(.subtle), in: Capsule())
                .contentShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(Palette.rose)
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .background(Palette.rose.opacity(.faint), in: Capsule())
        .overlay {
            Capsule()
                .stroke(Palette.rose.opacity(.muted), lineWidth: 1)
        }
    }

    var timeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle("時刻")

            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(ReminderModel.presets, id: \.self) { time in
                        let isSelected = !isPickingTime && model.time == time

                        timeButton("\(time.hour)", isSelected: isSelected) {
                            isPickingTime = false

                            Task {
                                await model.choose(time)
                            }
                        }
                    }

                    timeButton("…", isSelected: isPickingTime) {
                        isPickingTime = true
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)

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
                .card()
                .transition(.opacity)
            }
        }
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

            Text("記録か「支出なし」の印がある日は届きません")
                .textFont(.caption2)
                .foregroundStyle(Palette.subtext)
                .padding(.leading, 8)
        }
    }

    var notificationCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "yensign")
                .sansFont(.body, weight: .medium)
                .foregroundStyle(Palette.cardBottom)
                .frame(width: 38, height: 38)
                .background(
                    Palette.accent,
                    in: .rect(cornerRadius: corner.radius(9))
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

    var recurringNote: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsSectionTitle("固定費の通知")

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "repeat")
                    .sansFont(.small)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 28, height: 28)
                    .background(Palette.accent.opacity(.subtle), in: Circle())

                Text(recurringText)
                    .textFont(.footnote)
                    .foregroundStyle(Palette.subtext)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(cornerRadius: 20)

            if !model.upcomingNotices.isEmpty {
                VStack(spacing: 0) {
                    ForEach(model.upcomingNotices, id: \.self) { notice in
                        noticeRow(notice)
                    }
                }
                .padding(.horizontal, 16)
                .card(cornerRadius: 20)
            }
        }
    }

    func timeButton(
        _ title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let color = isSelected ? Palette.accentStrong : Palette.subtext
        let weight: Font.Weight = isSelected ? .semibold : .regular

        return Button(action: action) {
            Text(title)
                .textFont(.subheadline, weight: weight)
                .monospacedDigit()
                .foregroundStyle(color)
                .frame(width: 48, height: 48)
                .background(SettingsTile.fill(isSelected: isSelected), in: Circle())
                .overlay {
                    Circle()
                        .stroke(SettingsTile.stroke(isSelected: isSelected), lineWidth: 1)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
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
    static let onOptions: [CapsulePicker<Bool>.Option] = [
        .init("オフ", value: false),
        .init("オン", value: true)
    ]

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
        model.isOn ? "記録のない日だけ、そっと\nお知らせします" : "記録を忘れても、\nお知らせしません"
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

    func showPreview(by step: Int) {
        let index = Self.days.firstIndex(of: model.previewDay) ?? 0
        let next = (index + step + Self.days.count) % Self.days.count

        model.showPreview(on: Self.days[next])
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
