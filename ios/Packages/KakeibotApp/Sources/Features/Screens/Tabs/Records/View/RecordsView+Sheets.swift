import Core
import DesignSystem
import FeatureModels
import SwiftUI

extension RecordsView {
    @ViewBuilder
    func sheetContent(_ sheet: RecordsModel.Presented) -> some View {
        switch sheet {
        case .markMenu:
            EmptyView()

        case let .stamp(date):
            RecordsStampSheet(
                isAdding: Bindable(model.state).fields.isAddingMark,
                date: date,
                choices: model.output.stampChoices,
                current: model.output.stampIcon(on: date),
                editModel: model.stampEditModel
            ) { icon in
                layout.stampPulse += 1

                model.perform {
                    await $0.stamp(icon, on: date)
                }
            } onRemove: {
                model.perform {
                    await $0.removeStamp(on: date)
                }
            }

        case let .reward(date):
            RecordsRewardSheet(model: model, date: date)

        case let .batch(target):
            RecordsBatchSheet(
                model: model,
                target: target,
                count: selection?.count ?? 0
            ) { change in
                onChangeEntries(Array(selection ?? []), change)
                finishSelecting()
            }

        case .filter:
            RecordsFilterSheet(model: model)

        case let .adjustment(row):
            RecordsAdjustmentSheet(row: row) {
                model.perform {
                    await $0.deleteAdjustment(row.id)
                }
            }
        }
    }
}
