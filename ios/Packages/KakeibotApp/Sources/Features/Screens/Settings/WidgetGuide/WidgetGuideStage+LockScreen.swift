import DesignSystem
import SwiftUI

extension WidgetGuideStage {
    var lockScreen: some View {
        VStack(spacing: 4) {
            Label(
                "今月あと \(AmountText.text(FeatureArtSample.remaining))",
                systemImage: "yensign.circle"
            )
            .font(.system(size: 13, weight: .semibold))
            .monospacedDigit()
            .opacity(0.85)

            Text("9:41")
                .font(.system(size: 76, weight: .semibold, design: .rounded))
                .monospacedDigit()

            HStack(spacing: 12) {
                lockCircle

                lockRectangle
            }
            .padding(.top, 4)
        }
        .foregroundStyle(.white)
    }

    var lockCircle: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.3), lineWidth: 6)

            Circle()
                .trim(from: 0, to: 0.62)
                .stroke(.white, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("あと")
                    .font(.system(size: 9))

                Text("4.2万")
                    .font(.system(size: 15, weight: .bold))
                    .monospacedDigit()
            }
        }
        .padding(4)
        .frame(width: 72, height: 72)
        .background(.white.opacity(0.14), in: Circle())
    }

    var lockRectangle: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(alignment: .firstTextBaseline) {
                Text("今月あといくら")
                    .font(.system(size: 12))

                Spacer(minLength: 4)

                Text("あと 12 日")
                    .font(.system(size: 10))
                    .opacity(0.7)
            }

            Text(AmountText.text(FeatureArtSample.remaining))
                .font(.system(size: 22, weight: .bold))
                .monospacedDigit()

            Text("今日の支出 \(AmountText.text(FeatureArtSample.todayExpense))")
                .font(.system(size: 11))
                .monospacedDigit()
                .opacity(0.7)
        }
        .padding(.horizontal, 12)
        .frame(width: 176, height: 72)
        .background(.white.opacity(0.14), in: .rect(cornerRadius: 16))
    }
}
