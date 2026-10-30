import Core
import DesignSystem
import SwiftUI

extension WalletEditSheet {
    var content: some View {
        VStack(spacing: 16) {
            SettingsEditHeader(
                title: title,
                isEditing: model.isEditing,
                isHidden: model.isHidden,
                canDelete: !(model.isHidden && model.hasEntries)
            ) {
                close()
            } onHide: {
                toggleHidden()
            } onDelete: {
                focus = nil
                isConfirmingDelete = true
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        preview

                        colorNote
                    }
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .global).maxY
                    } action: { maxY in
                        iconBottom = maxY
                    }

                    SettingsField("名前", text: $model.name, focus: $focus, field: .name)

                    kindChooser

                    balanceField

                    if model.showsValuation {
                        valuationField
                    }

                    if !rowItems.isEmpty {
                        SettingsRowList(items: rowItems) { panel in
                            open(panel)
                        }
                    }
                }
                .padding(.bottom, 8)
                .padding(.vertical, Self.fade)
            }
            .scrollIndicators(.hidden)
            .edgeFade(Self.fade)
            .padding(.vertical, -Self.fade)
            .scrollDismissesKeyboard(.interactively)

            saveButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
        .contentShape(.rect)
        .onTapGesture {
            focus = nil
        }
        .background {
            Backdrop()
                .ignoresSafeArea()
        }
    }

    var saveButton: some View {
        PrimaryButton(model.saveTitle) {
            Task {
                await save()
            }
        }
        .disabled(!model.canSave)
    }

    var preview: some View {
        WalletRowCard(
            name: previewName,
            kind: model.kind,
            amount: model.initialBalance,
            caption: "最初の残高"
        ) {
            Button {
                focus = nil
                isEditingIcon = true
            } label: {
                WalletRowIcon(
                    icon: model.icon.preview,
                    stroke: iconStroke,
                    strokeWidth: iconStrokeWidth
                )
                .overlay(alignment: .bottomTrailing) {
                    EditBadge()
                        .offset(x: 4, y: 4)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }

    var colorNote: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: model.icon.color) ?? Palette.subtext)
                .frame(width: 10, height: 10)

            Text("アイコンの色は、振り返りのグラフの色になります")
                .tracking(1)
        }
        .textFont(.caption2)
        .foregroundStyle(Palette.subtext)
        .frame(maxWidth: .infinity)
    }

    var kindChooser: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("種類")

            LazyVGrid(columns: Self.kindColumns, spacing: 8) {
                ForEach(Wallet.Kind.allCases, id: \.self) { kind in
                    kindButton(kind)
                }
            }
        }
    }

    var balanceField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("最初の残高")

            HStack(spacing: 12) {
                Button {
                    model.isNegative.toggle()
                } label: {
                    Image(systemName: signSymbol)
                        .sansFont(.body, weight: .semibold)
                        .foregroundStyle(signColor)
                        .frame(width: 46, height: 46)
                        .background(signFill, in: .rect(cornerRadius: corner.radius(16)))
                        .overlay {
                            RoundedRectangle(cornerRadius: corner.radius(16))
                                .stroke(signColor.opacity(0.6), lineWidth: 1)
                        }
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .haptic(.selection, trigger: model.isNegative)

                Button {
                    openAmount()
                } label: {
                    HStack(spacing: 8) {
                        Text(AmountText.text(model.calculator.amount))
                            .displayFont(.headline)
                            .monospacedDigit()
                            .foregroundStyle(Palette.text)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)

                        Spacer(minLength: 8)

                        EditBadge()
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 12)
                    .frame(height: 46)
                    .background(Palette.panel, in: .rect(cornerRadius: corner.radius(16)))
                    .overlay {
                        RoundedRectangle(cornerRadius: corner.radius(16))
                            .stroke(amountStroke, lineWidth: 1)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            SettingsCaption(balanceHint)
                .contentTransition(.opacity)
                .animation(.snappy, value: model.kind == .card)
        }
    }

    var valuationField: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsRowList(items: valuationItems) { panel in
                open(panel)
            }

            SettingsCaption("値動きの分は、収入や支出に入れず、残高だけを合わせます。")

            if !model.valuations.isEmpty {
                valuationHistory
            }
        }
    }

    var valuationHistory: some View {
        VStack(alignment: .leading, spacing: 8) {
            SettingsSectionTitle("これまでの評価額")
                .padding(.top, 12)

            ForEach(model.valuations) { valuation in
                SwipeRow(id: valuation.id, openId: $openValuationId) {
                    openValuationId = nil
                } onAction: {
                    Task {
                        valuationDeletion = await model.deleteValuation(valuation.id)
                    }
                } content: {
                    valuationRow(valuation)
                }
            }

            SettingsCaption("横に払うと消せます。\n消すと、前の評価額から数え直します。")
        }
    }

    func amountDrawer(
        _ title: String,
        calculator: AmountCalculator,
        onPress: @escaping (AmountCalculator.Key) -> Void,
        onDismiss: @escaping () -> Void,
        onDone: @escaping () -> Void,
        @ViewBuilder button: () -> some View
    ) -> some View {
        Group {
            Palette.scrim
                .opacity(0.35)
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
                    SettingsKeypadValue(calculator.amount)

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
            Text("\(String(date.year))/\(date.month)/\(date.day)")
                .textFont(.subheadline)
                .monospacedDigit()
                .foregroundStyle(Palette.subtext)

            Spacer(minLength: 8)

            Text(AmountText.text(valuation.amount))
                .displayFont(.body)
                .monospacedDigit()
                .foregroundStyle(Palette.accentStrong)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .card(cornerRadius: 16)
    }

    func kindButton(_ kind: Wallet.Kind) -> some View {
        let isSelected = model.kind == kind
        let textColor = isSelected ? Palette.accentStrong : Palette.subtext
        let fill = isSelected ? Palette.accent.opacity(.subtle) : Color.clear
        let stroke = isSelected ? Palette.accent : Palette.accent.opacity(.soft)

        return Button {
            model.kind = kind
        } label: {
            Text(kind.title)
                .textFont(.footnote)
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(fill, in: Capsule())
                .overlay {
                    Capsule()
                        .stroke(stroke, lineWidth: 1)
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .haptic(.selection, trigger: isSelected)
    }
}
