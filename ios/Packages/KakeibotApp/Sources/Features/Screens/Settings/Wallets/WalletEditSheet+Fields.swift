import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension WalletEditSheet {
    var content: some View {
        SettingsEditForm(showsSave: focus == nil) {
            SettingsPreviewSection(
                note: "アイコンの色は、枠と振り返りのグラフに使います",
                dot: noteColor
            ) {
                preview
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.frame(in: .global).maxY
            } action: { maxY in
                layout.iconBottom = maxY
            }

            SettingsField(
                "名前",
                text: Bindable(model.state).fields.name,
                focus: $focus,
                field: .name
            )

            SettingsFormCard {
                kindChooser

                balanceField
            }

            if model.output.showsValuation {
                valuationField
            }

            if !rowItems.isEmpty {
                SettingsDetails {
                    SettingsRowList(items: rowItems) { panel in
                        open(panel)
                    }
                }
            }
        } save: {
            saveButton
        }
        .overlay(alignment: .top) {
            header
        }
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .backdrop()
    }

    var header: some View {
        SettingsEditHeader(
            isMenuOpen: Bindable(model.flow.state).presented.prompt[.menu],
            title: title,
            isEditing: model.flow.output.isEditing,
            isHidden: model.flow.output.isHidden,
            canDelete: !(model.flow.output.isHidden && model.input.hasEntries)
        ) {
            focus = nil
            model.flow.close()
        } onHide: {
            focus = nil
            model.flow.toggleHidden()
        } onDelete: {
            focus = nil
            model.flow.state.presented.prompt.show(.delete)
        }
        .padding(.horizontal, SettingsSpacing.side)
        .padding(.top, SettingsSpacing.top)
    }

    var saveButton: some View {
        PrimaryButton(model.flow.output.saveTitle) {
            save()
        }
        .disabled(!model.flow.output.canSave)
    }

    var preview: some View {
        WalletRowCard(
            name: previewName,
            kind: model.state.kind,
            amount: model.output.initialBalance,
            caption: "最初の残高"
        ) {
            Button {
                focus = nil
                model.state.submodels.icon.present()
            } label: {
                WalletRowIcon(
                    icon: model.state.submodels.icon.preview,
                    strokeWidth: iconStrokeWidth
                )
                .overlay(alignment: .bottomTrailing) {
                    EditBadge()
                        .offset(x: 8, y: 4)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    var balanceField: some View {
        SettingsFormSection("最初の残高") {
            HStack(spacing: 8) {
                signButton(isNegative: false)
                signButton(isNegative: true)
            }

            Button {
                openAmount()
            } label: {
                HStack(spacing: 8) {
                    Text(model.output.balanceText)
                        .displayFont(.headline)
                        .monospacedDigit()
                        .foregroundStyle(signColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Spacer(minLength: 8)

                    EditBadge()
                }
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .frame(height: 46)
                .background(signColor.opacity(.subtle), in: .rect(cornerRadius: corner.radius(16)))
                .overlay {
                    RoundedRectangle(cornerRadius: corner.radius(16))
                        .stroke(amountStroke, lineWidth: 1)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            SettingsNote(balanceHint)
                .contentTransition(.opacity)
                .animation(.snappy, value: model.state.kind)
        }
    }

    var valuationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsRowList(items: valuationItems) { panel in
                open(panel)
            }

            SettingsNote("値動きの分は、収入や支出に入れず、残高だけを合わせます。")

            if !model.input.valuations.isEmpty {
                valuationHistory
            }
        }
    }

    var valuationHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("これまでの評価額")
                .padding(.top, 12)

            ForEach(model.input.valuations) { valuation in
                SwipeRow(
                    id: valuation.id,
                    openId: Bindable(model.state).presented.openValuation.item
                ) {
                    model.state.presented.openValuation.closeAll()
                } onAction: {
                    model.perform {
                        await $0.deleteValuation(valuation.id)
                    }
                } content: {
                    valuationRow(valuation)
                }
            }

            SettingsNote("横に払うと消せます。\n消すと、前の評価額から数え直します。")
        }
    }

    func amountDrawer(
        _ title: String,
        calculator: AmountCalculator,
        amount: Int? = nil,
        onPress: @escaping (AmountCalculator.Key) -> Void,
        onDismiss: @escaping () -> Void,
        onDone: @escaping () -> Void
    ) -> some View {
        amountDrawer(
            title,
            calculator: calculator,
            amount: amount,
            onPress: onPress,
            onDismiss: onDismiss,
            onDone: onDone
        ) {
            EmptyView()
        }
    }

    func amountDrawer(
        _ title: String,
        calculator: AmountCalculator,
        amount: Int? = nil,
        onPress: @escaping (AmountCalculator.Key) -> Void,
        onDismiss: @escaping () -> Void,
        onDone: @escaping () -> Void,
        @ViewBuilder button: () -> some View
    ) -> some View {
        Group {
            Scrim(.drawer)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
                .transition(.opacity)
                .zIndex(1)

            SettingsDrawer(title, showsDone: false) {
                onDone()
            } content: {
                VStack(spacing: 12) {
                    SettingsKeypadAmount(amount ?? calculator.amount)

                    Keypad(calculator: calculator) {
                        onDone()
                    } onKey: { key in
                        onPress(key)
                    }

                    button()
                }
            }
            .transition(.settingsDrawer)
            .zIndex(1)
        }
    }

    func valuationRow(_ valuation: Valuation) -> some View {
        let date = valuation.date

        return HStack {
            Text("\(String(date.year))/\(date.monthDayText)")
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 8)

            AmountText(valuation.amount, font: .size(.body), color: Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .card(cornerRadius: 16)
    }

    func signButton(isNegative: Bool) -> some View {
        let isSelected = model.state.isNegative == isNegative
        let tint = isNegative ? Palette.rose : Palette.accent
        let color = isSelected ? tint : Palette.subtext
        let fill = isSelected ? tint.opacity(.subtle) : Color.clear
        let stroke = isSelected ? tint : Palette.accent.opacity(.soft)
        let shape = RoundedRectangle(cornerRadius: corner.radius(16))

        return Button {
            withAnimation(.snappy) {
                model.state.setNegative(isNegative)
            }
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                        .sansFont(.small)

                    Text(isNegative ? "払う・返す分" : "お金がある")
                        .textFont(.footnote, weight: .semibold)
                }

                Text(isNegative ? "未払い・借入" : "残高・貯金")
                    .textFont(.caption2)
                    .foregroundStyle(isSelected ? tint : Palette.hint)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(fill, in: shape)
            .overlay {
                shape
                    .stroke(stroke, lineWidth: isSelected ? 1.5 : 1)
            }
            .contentShape(shape)
        }
        .buttonStyle(.plain)
        .haptic(.selection, trigger: isSelected)
    }
}
