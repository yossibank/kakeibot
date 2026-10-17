import Core
import DesignSystem
import Store
import SwiftUI

public struct OnboardingView: View {
    @State private var model: MonthStartDayModel
    @State private var errorMessage: String?

    private let database: AppDatabase
    private let onFinish: () -> Void

    public init(
        database: AppDatabase,
        today: LocalDate,
        onFinish: @escaping () -> Void
    ) {
        _model = State(
            initialValue: MonthStartDayModel(database: database, today: today)
        )

        self.database = database
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 8) {
                Text("ようこそ")
                    .font(.system(size: 22, design: .serif))
                    .tracking(6)
                    .foregroundStyle(Palette.gold)

                Text("はじめに、1 か月をどの日から数えるかを決めます")
                    .font(.subheadline)
                    .foregroundStyle(Palette.champagne)
                    .multilineTextAlignment(.center)

                Text("給料日に合わせると、給料日から次の給料日の前の日までを 1 か月として数えます")
                    .font(.caption)
                    .foregroundStyle(Palette.mist)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 18) {
                    PeriodCard(
                        periodText: model.periodText,
                        month: model.month
                    )

                    MonthStartDayGrid(selection: model.startDay) { day in
                        Task {
                            await model.choose(day)
                        }
                    }

                    Text("あとで設定の「月の始まり」から変えられます")
                        .font(.caption2)
                        .foregroundStyle(Palette.mist)

                    if let message = errorMessage ?? model.errorMessage {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(Palette.rose)
                    }
                }
                .padding(.vertical, 8)
            }
            .scrollIndicators(.hidden)

            PrimaryButton("はじめる") {
                Task {
                    await finish()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            Rectangle()
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.selection, trigger: model.startDay)
        .task {
            await model.load()
        }
    }
}

private extension OnboardingView {
    static let saveFailedMessage = "設定を保存できませんでした"

    func finish() async {
        do {
            try await database.completeOnboarding()
            onFinish()
        } catch {
            errorMessage = Self.saveFailedMessage
        }
    }
}
