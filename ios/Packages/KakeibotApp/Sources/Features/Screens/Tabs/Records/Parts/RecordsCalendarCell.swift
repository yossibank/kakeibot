import Core
import DesignSystem
import SwiftUI

struct RecordsCalendarCell: View {
    @Environment(\.themeStyle.corner) private var corner

    let day: Int
    let dayColor: Color
    let isShown: Bool
    let isToday: Bool
    let isDimmed: Bool
    let stamp: Icon?
    let expense: Int
    let income: Int
    let isNoSpend: Bool
    let hasUpcoming: Bool
    var heat: Double = 0
    let onSelect: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(String(day))
                .displayFont(.body)
                .foregroundStyle(dayColor)
                .frame(width: 30, height: 30)
                .background {
                    if isShown {
                        Circle()
                            .fill(Palette.accent)
                    } else if isToday {
                        Circle()
                            .stroke(Palette.accent, lineWidth: 1)
                    }
                }
                .overlay(alignment: .topTrailing) {
                    if let stamp {
                        IconSeal(stamp, size: 22)
                            .offset(x: 11, y: -9)
                            .id(stamp.id)
                            .transition(Self.stampTransition)
                    }
                }
                .animation(Self.stampAnimation, value: stamp?.id)

            VStack(spacing: 0) {
                markLine {
                    if expense > 0 {
                        markAmount(expense, type: .expense)
                    } else if isNoSpend {
                        Image(systemName: "leaf.fill")
                            .sansFont(.micro)
                            .foregroundStyle(Palette.accent)
                    } else if hasUpcoming {
                        Image(systemName: "repeat")
                            .sansFont(.micro)
                            .foregroundStyle(Palette.hint)
                    }
                }

                markLine {
                    if income > 0 {
                        markAmount(income, type: .income)
                    }
                }
            }
        }
        .opacity(isDimmed ? 0.45 : 1)
        .frame(maxWidth: .infinity, minHeight: 66)
        .background {
            if heat > 0 {
                RoundedRectangle(cornerRadius: corner.radius(12))
                    .fill(Palette.accent.opacity(Self.heatFloor + Self.heatRange * heat))
                    .padding(2)
            }
        }
        .contentShape(.rect)
        .onTapGesture(perform: onSelect)
    }
}

extension RecordsCalendarCell: Equatable {
    nonisolated static func == (
        lhs: RecordsCalendarCell,
        rhs: RecordsCalendarCell
    ) -> Bool {
        lhs.day == rhs.day
            && lhs.dayColor == rhs.dayColor
            && lhs.isShown == rhs.isShown
            && lhs.isToday == rhs.isToday
            && lhs.isDimmed == rhs.isDimmed
            && lhs.stamp == rhs.stamp
            && lhs.expense == rhs.expense
            && lhs.income == rhs.income
            && lhs.isNoSpend == rhs.isNoSpend
            && lhs.hasUpcoming == rhs.hasUpcoming
            && lhs.heat == rhs.heat
    }
}

private extension RecordsCalendarCell {
    static let markLineHeight: CGFloat = 14
    static let heatFloor = 0.05
    static let heatRange = 0.3

    static var stampTransition: AnyTransition {
        .scale(scale: 0.2).combined(with: .opacity)
    }

    static var stampAnimation: Animation {
        .bouncy(duration: 0.45, extraBounce: 0.25)
    }

    func markLine(@ViewBuilder _ content: () -> some View) -> some View {
        Color.clear
            .frame(height: Self.markLineHeight)
            .overlay {
                content()
            }
    }

    func markAmount(
        _ amount: Int,
        type: Entry.Kind
    ) -> some View {
        AmountText(amount, type: type, font: .size(.caption), isCompact: true)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 2)
    }
}
