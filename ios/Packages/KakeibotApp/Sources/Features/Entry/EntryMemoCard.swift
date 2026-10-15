import DesignSystem
import SwiftUI

struct EntryMemoCard: View {
    @Bindable var model: EntryModel

    let isFocused: FocusState<Bool>.Binding
    let pointerX: CGFloat
    let onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("メモ", systemImage: "square.and.pencil")
                    .font(.caption)
                    .foregroundStyle(Palette.gold)

                Spacer()

                Button("完了", action: onDone)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Palette.gold)
                    .frame(minWidth: 44, minHeight: 32)
            }

            TextField(
                "メモ",
                text: $model.memo,
                prompt: Text("メモを書く").foregroundStyle(Palette.dusk),
                axis: .vertical
            )
            .lineLimit(1...4)
            .font(.subheadline)
            .foregroundStyle(Palette.ink)
            .tint(Palette.gold)
            .focused(isFocused)

            if !model.recentMemos.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 6) {
                        ForEach(model.recentMemos, id: \.self) { memo in
                            suggestionButton(memo)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .padding(14)
        .background(Palette.drawer, in: .rect(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Palette.gold.opacity(0.55), lineWidth: 1)
        }
        .overlay(alignment: .bottomLeading) {
            pointer
        }
        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
        .task {
            isFocused.wrappedValue = true
        }
    }
}

private extension EntryMemoCard {
    static let pointerSize = CGSize(width: 18, height: 9)

    var pointer: some View {
        let size = Self.pointerSize

        return ZStack {
            BalloonPointer(isClosed: true)
                .fill(Palette.drawer)

            BalloonPointer(isClosed: false)
                .stroke(Palette.gold.opacity(0.55), lineWidth: 1)
        }
        .frame(width: size.width, height: size.height)
        .offset(x: pointerX - size.width / 2, y: size.height - 1)
    }

    func suggestionButton(_ memo: String) -> some View {
        Button(memo) {
            model.memo = memo
        }
        .font(.caption)
        .foregroundStyle(Palette.ink)
        .lineLimit(1)
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .overlay(Capsule().stroke(Palette.line, lineWidth: 1))
        .buttonStyle(.plain)
    }
}

private struct BalloonPointer: Shape {
    let isClosed: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        if isClosed {
            path.closeSubpath()
        }

        return path
    }
}
