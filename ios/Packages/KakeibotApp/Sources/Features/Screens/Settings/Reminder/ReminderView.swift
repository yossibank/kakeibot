import Core
import DesignSystem
import FeatureModels
import SwiftUI

public struct ReminderView: View {
    @State var model: ReminderModel

    @Environment(\.themeStyle.corner) var corner

    @Environment(\.scenePhase) private var scenePhase

    public init(model: ReminderModel) {
        _model = State(initialValue: model)
    }

    public var body: some View {
        VStack(spacing: SettingsSpacing.header) {
            SettingsBackHeader("記録忘れの通知", hint: hint)

            SettingsIntroCard(
                systemImage: "bell",
                headline: ("記録のない日だけ", "そっとお知らせします"),
                notes: [
                    .init("checkmark.circle", "記録か「支出なし」の日は届きません"),
                    .init("repeat", recurringText)
                ],
                hint: hint
            )

            sections
        }
        .settingsScreen(errorNotice: Bindable(model.state).errorNotice)
        .animation(.snappy, value: model.input.time)
        .animation(.snappy, value: model.output.isDenied)
        .animation(.snappy, value: isPickingTime)
        .animation(.snappy, value: model.state.previewDay)
        .transaction(value: model.output.isSettled) { transaction in
            transaction.disablesAnimations = true
        }
        .haptic(.selection, trigger: model.input.time)
        .haptic(.selection, trigger: model.state.previewDay)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.perform {
                    await $0.refreshAuthorization()
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
        model.input.time?.description ?? "オフ"
    }
}

private extension ReminderView {
    var sections: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SettingsSpacing.section) {
                VStack(spacing: 12) {
                    hero

                    if model.output.isDenied {
                        NotificationDeniedBanner()
                            .transition(.opacity)
                    }
                }

                if model.output.isOn {
                    timeSection
                        .transition(.opacity)

                    previewSection
                        .transition(.opacity)
                }

                if !model.output.upcomingNotices.isEmpty {
                    recurringSection
                }
            }
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

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
                    isActive: model.output.isOn
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
                        let isSelected = !isPickingTime && model.input.time == time

                        timeButton("\(time.hour)", isSelected: isSelected) {
                            model.state.presented.close(.timePicker)

                            model.perform {
                                await $0.choose(time)
                            }
                        }
                    }

                    timeButton("…", isSelected: isPickingTime) {
                        model.state.presented.show(.timePicker)
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
                .background(SettingsTileStyle.fill(isSelected: isSelected), in: Circle())
                .overlay {
                    Circle()
                        .stroke(SettingsTileStyle.stroke(isSelected: isSelected), lineWidth: 1)
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

    var isPickingTime: Bool {
        model.state.presented[.timePicker]
    }

    var bellImage: String {
        model.output.isOn ? "bell.badge" : "bell.slash"
    }

    var timeColor: Color {
        model.output.isOn ? Palette.accentStrong : Palette.hint
    }

    var summaryText: String {
        model.output.isOn ? "記録のない日に届きます" : "通知は届きません"
    }

    var onBinding: Binding<Bool> {
        Binding {
            model.output.isOn
        } set: { isOn in
            model.perform {
                await $0.setOn(isOn)
            }
        }
    }

    var dateBinding: Binding<Date> {
        Binding {
            let time = model.input.time ?? .evening

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

            model.perform {
                await $0.choose(time)
            }
        }
    }

    var hint: SettingsFold {
        SettingsFold(\.hint, in: model)
    }
}

#Preview {
    if let parts = ScreenParts.preview() {
        NavigationStack {
            ReminderView(
                model: ReminderModel(
                    parts: parts,
                    today: LocalDate(Date(), in: .current),
                    time: .evening,
                    permission: .allowed
                )
            )
        }
    }
}
