import DesignSystem
import SwiftUI

struct EntryDeletionBanner: View {
    @State private var remaining = 1.0

    let change: EntryChange
    let seconds: Int
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            NoticeMark(systemImage: "trash", tone: .error)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 4) {
                    subject

                    amountAndPredicate
                }

                VStack(alignment: .leading, spacing: 2) {
                    subject

                    amountAndPredicate
                }

                VStack(alignment: .leading, spacing: 2) {
                    subject

                    amount

                    predicate
                }
            }
            .textFont(.footnote)
            .foregroundStyle(Palette.text)
            .layoutPriority(1)

            Spacer(minLength: 8)

            undoButton
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .frame(minHeight: 54)
        .overlay(alignment: .bottom) {
            timeLine
        }
        .noticeCapsule(.error)
        .shadow(color: Palette.shadow.opacity(0.5), radius: 20, y: 10)
        .onAppear {
            withAnimation(.linear(duration: Double(seconds))) {
                remaining = 0
            }
        }
    }
}

private extension EntryDeletionBanner {
    var subject: some View {
        Text(change.subject)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    var amount: some View {
        Text(change.amountText)
            .monospacedDigit()
            .fixedSize()
    }

    var predicate: some View {
        Text(change.predicate)
            .fixedSize()
    }

    var amountAndPredicate: some View {
        HStack(spacing: 4) {
            amount

            predicate
        }
    }

    var undoButton: some View {
        Button(action: onUndo) {
            Text("取り消す")
                .textFont(.caption, weight: .semibold)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 16)
                .frame(height: 34)
                .goldFace()
        }
        .buttonStyle(.plain)
    }

    var timeLine: some View {
        Capsule()
            .fill(Palette.rose.opacity(0.7))
            .frame(height: 2)
            .scaleEffect(x: remaining, anchor: .leading)
            .padding(.horizontal, 28)
            .padding(.bottom, 4)
    }
}
