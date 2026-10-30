import Core
import DesignSystem
import Store
import SwiftUI

public struct ReminderView: View {
    @State var model: ReminderModel

    @Environment(\.themeStyle.corner) var corner

    @State private var isPickingTime = false

    @Environment(\.scenePhase) private var scenePhase

    public init(model: ReminderModel) {
        _model = State(initialValue: model)
        _isPickingTime = State(initialValue: model.isCustom)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("記録忘れの通知")

            ScrollView {
                VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                    SettingsIntroCard(
                        systemImage: "bell",
                        headline: ("記録のない日だけ", "そっとお知らせします"),
                        notes: [
                            .init("checkmark.circle", "記録か「支出なし」の日は届きません"),
                            .init("repeat", recurringText)
                        ]
                    )

                    VStack(spacing: 12) {
                        hero

                        if model.isDenied {
                            NotificationDeniedBanner()
                                .transition(.opacity)
                        }
                    }

                    if model.isOn {
                        timeSection
                            .transition(.opacity)

                        previewSection
                            .transition(.opacity)
                    }

                    if !model.upcomingNotices.isEmpty {
                        recurringSection
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, 20)
        .padding(.top, SettingsSpacing.top)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .errorBanner(model.errorNotice) {
            model.errorNotice.clear()
        }
        .background {
            Backdrop()
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
        .haptic(.selection, trigger: model.time)
        .haptic(.selection, trigger: model.previewDay)
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

extension ReminderView {
    var timeText: String {
        model.time?.description ?? "オフ"
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
}

private extension ReminderView {
    static let onOptions: [CapsulePicker<Bool>.Option] = [
        .init("オフ", value: false),
        .init("オン", value: true)
    ]

    var bellImage: String {
        model.isOn ? "bell.badge" : "bell.slash"
    }

    var timeColor: Color {
        model.isOn ? Palette.accentStrong : Palette.hint
    }

    var summaryText: String {
        model.isOn ? "記録のない日に届きます" : "通知は届きません"
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
