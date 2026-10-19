import DesignSystem
import SwiftUI

public struct AppIconListView: View {
    @Bindable private var model: AppIconListModel

    @Environment(\.dismiss) private var dismiss

    public init(model: AppIconListModel) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: 14) {
            header

            ScrollView {
                LazyVGrid(columns: Self.columns, spacing: 18) {
                    ForEach(AppIconChoice.allCases, id: \.self) { choice in
                        tile(choice)
                    }
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
                .fill(Palette.night)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .sensoryFeedback(.selection, trigger: model.current)
    }
}

private extension AppIconListView {
    var header: some View {
        HStack {
            RingButton(systemImage: "chevron.left") {
                dismiss()
            }

            Spacer()

            Text("アプリアイコン")
                .font(.serif(.body))
                .tracking(4)
                .foregroundStyle(Palette.gold)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
    }

    func tile(_ choice: AppIconChoice) -> some View {
        let isCurrent = choice == model.current
        let ring = isCurrent ? Palette.gold : Color.clear
        let titleColor = isCurrent ? Palette.champagne : Palette.mist

        return Button {
            Task {
                await model.select(choice)
            }
        } label: {
            VStack(spacing: 8) {
                AppIconPreview(choice: choice, size: 76)
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(ring, lineWidth: 2)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isCurrent {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Palette.gold, Palette.night)
                                .offset(x: 6, y: 6)
                        }
                    }

                Text(choice.title)
                    .font(.footnote)
                    .foregroundStyle(titleColor)
            }
            .frame(maxWidth: .infinity)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

private extension AppIconListView {
    static let columns = Array(
        repeating: GridItem(.flexible(), spacing: 12),
        count: 3
    )
}
