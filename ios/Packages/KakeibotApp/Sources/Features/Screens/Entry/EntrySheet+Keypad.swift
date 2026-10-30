import Core
import DesignSystem
import SwiftUI

extension EntrySheet {
    var keypadDrawer: some View {
        VStack(spacing: 12) {
            if model.keypadTarget == .fee {
                FeeChoiceRow(
                    choices: model.feeChoices,
                    selection: model.fee
                ) { amount in
                    model.setFee(amount)
                }
            } else if model.type != .transfer {
                EntryTemplateRow(
                    model: model,
                    isCompact: true,
                    onUse: { template in
                        useTemplate(template)
                    },
                    onAdd: {
                        open(.newTemplate)
                    }
                )
            }

            Keypad(calculator: model.activeCalculator) {
                setEnteringAmount(false)
            } onKey: { key in
                model.press(key)
            }

            saveButtons
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background {
            drawerShape
                .fill(Palette.panel)
                .overlay {
                    drawerShape
                        .stroke(Palette.accent.opacity(.muted), lineWidth: 1)
                }
                .ignoresSafeArea(edges: .bottom)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height
        } action: { height in
            drawerHeight = height
        }
    }
}

extension EntrySheet {
    func setEnteringAmount(_ isEntering: Bool) {
        withAnimation(.snappy) {
            isEnteringAmount = isEntering

            if !isEntering {
                model.enter(.amount)
            }
        }
    }

    func tapDial() {
        guard model.keypadTarget == .fee else {
            setEnteringAmount(!isEnteringAmount)
            return
        }

        withAnimation(.snappy) {
            model.enter(.amount)
        }
    }

    func enterFee() {
        withAnimation(.snappy) {
            model.enter(.fee)
        }

        setEnteringAmount(true)
    }
}

private extension EntrySheet {
    var drawerShape: UnevenRoundedRectangle {
        let radius = corner.radius(28)

        return UnevenRoundedRectangle(
            topLeadingRadius: radius,
            topTrailingRadius: radius
        )
    }
}
