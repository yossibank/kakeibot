import FeatureModels

@MainActor
struct SettingsFold {
    let input: SettingsFoldInput
    let load: () async -> Void
    let setClosed: (Bool) -> Void

    init<Model: SettingsFoldModel>(
        _ fold: KeyPath<Model.Input, SettingsFoldInput>,
        in model: Model
    ) {
        self.input = model.input[keyPath: fold]

        self.load = {
            await model.loadFold(fold)
        }

        self.setClosed = { isClosed in
            model.setFold(fold, closed: isClosed)
        }
    }
}

extension SettingsFold {
    var isClosed: Bool {
        input.isClosed == true
    }
}
