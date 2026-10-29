import Core
import DesignSystem
import Store
import SwiftUI
import UIKit

public struct ReminderView: View {
    @State var model: ReminderModel

    @Environment(\.themeStyle.corner) var corner

    @State private var isPickingTime = false

    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    public init(model: ReminderModel) {
        _model = State(initialValue: model)
        _isPickingTime = State(initialValue: model.isCustom)
    }

    public var body: some View {
        VStack(spacing: 20) {
            SettingsBackHeader("記録忘れの通知")

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
            SectionTitle("時刻")

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
        model.isOn ? "記録のない日だけ、そっと\nお知らせします" : "記録を忘れても、\nお知らせしません"
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
