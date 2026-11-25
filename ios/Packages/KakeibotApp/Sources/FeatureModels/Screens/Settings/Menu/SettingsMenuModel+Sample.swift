#if DEBUG
public extension SettingsMenuModel {
    func sampleModel() -> SettingsMenuSampleModel {
        SettingsMenuSampleModel(parts: dependencies)
    }
}
#endif
